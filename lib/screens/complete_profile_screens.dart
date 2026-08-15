import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/services/achievement_service.dart';
import 'package:LoveQuiz/services/photo_service.dart';
import 'package:LoveQuiz/services/user_services.dart';
import 'package:LoveQuiz/widgets/profile_avatar.dart';
import 'package:LoveQuiz/widgets/fade_slide_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool _loading = false;
  String _photoUrl = '';

  final List<String> _genders = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decir',
  ];
  final List<String> _maritalStatuses = [
    'Soltero/a',
    'En relación',
    'Casado/a',
    'Divorciado/a',
    'Viudo/a',
  ];

  // Libera los recursos de los controladores de texto.
  @override
  void dispose() {
    _aliasController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Valida los campos, guarda el perfil y navega al home.
  Future<void> _saveProfile() async {
    final alias = _aliasController.text.trim();
    final ageText = _ageController.text.trim();

    if (alias.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ingresa un alias")));
      return;
    }

    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age < 1 || age > 120) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ingresa una edad válida (1-120)")),
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => _loading = true);

    try {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        alias: alias,
        photoUrl: _photoUrl,
        gamesPlayed: 0,
        createdAt: Timestamp.now(),
        age: age,
        gender: _selectedGender,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
      );

      await UserService.createUser(newUser);
      await AchievementService.initAchievements();

      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Selecciona y sube una foto de perfil.
  Future<void> _pickPhoto() async {
    try {
      final result = await PhotoService.pickAndUploadPhoto(context);
      if (result == null || !mounted) return;
      setState(() => _photoUrl = result.url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Foto seleccionada")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al seleccionar foto: $e")));
    }
  }

  // Muestra un modal con opciones para cambiar o eliminar la foto.
  void _showPhotoOptions() {
    final ac = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: ac.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ac.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Foto de perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ac.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (_photoUrl.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: _PhotoOptionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Cambiar foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto();
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _PhotoOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Eliminar foto',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoUrl = '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Foto eliminada")),
                    );
                  },
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: _PhotoOptionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Seleccionar foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Decoración compartida para los campos del formulario.
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    final ac = AppColors.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: ac.surfaceAlt,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ac.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pink, width: 2),
      ),
    );
  }

  // Construye el formulario de completar perfil para nuevos usuarios.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);

    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        title: Text(
          'Completa tu perfil',
          style: TextStyle(color: ac.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ProfileAvatar(
                    size: 100,
                    imageUrl: _photoUrl.isNotEmpty ? _photoUrl : null,
                    borderColor: AppColors.pink,
                    borderWidth: 3,
                    onTap: _showPhotoOptions,
                    badge: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Alias (obligatorio)
                TextField(
                  controller: _aliasController,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  ],
                  decoration: _inputDecoration(
                    label: 'Alias *',
                    hint: 'Tu nombre de usuario',
                    icon: Icons.person_outline,
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 16),

                // Edad
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Edad',
                    hint: 'Ej: 25',
                    icon: Icons.cake_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Género
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: _inputDecoration(
                    label: 'Género',
                    icon: Icons.wc_outlined,
                  ),
                  items: _genders.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Ciudad
                TextField(
                  controller: _cityController,
                  decoration: _inputDecoration(
                    label: 'Ciudad',
                    hint: 'Tu ciudad de residencia',
                    icon: Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                // Estado civil
                DropdownButtonFormField<String>(
                  initialValue: _selectedMaritalStatus,
                  decoration: _inputDecoration(
                    label: 'Estado Civil',
                    icon: Icons.favorite_outline,
                  ),
                  items: _maritalStatuses.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMaritalStatus = newValue;
                    });
                  },
                ),
                const SizedBox(height: 30),

                // Texto de campos obligatorios
                Text(
                  '* Campos obligatorios',
                  style: TextStyle(fontSize: 12, color: ac.textMuted),
                ),
                const SizedBox(height: 16),

                // Botón de continuar
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text("Continuar"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  // Construye un botón de opción de foto con icono y etiqueta.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final effectiveColor = color ?? ac.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
