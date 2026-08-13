import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/services/couple_data_service.dart';
import 'package:LoveQuiz/services/photo_service.dart';
import 'package:LoveQuiz/services/user_services.dart';
import 'package:LoveQuiz/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';

const Color _pink = Color(0xFFFF2E93);

// Pantalla de edición de perfil con estilo profesional minimalista.
class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _aliasController;
  late TextEditingController _ageController;
  late TextEditingController _cityController;

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

  // Inicializa los controladores con los datos actuales del usuario.
  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.user.alias);
    _ageController = TextEditingController(
      text: widget.user.age?.toString() ?? '',
    );
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _selectedGender = widget.user.gender;
    _selectedMaritalStatus = widget.user.maritalStatus;
    _photoUrl = widget.user.photoUrl;
  }

  // Libera los recursos de los controladores de texto.
  @override
  void dispose() {
    _aliasController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Valida y guarda los cambios del perfil del usuario en Firestore.
  Future<void> _updateProfile() async {
    final alias = _aliasController.text.trim();

    if (alias.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ingresa un alias")));
      return;
    }

    final ageText = _ageController.text.trim();

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
      final updatedUser = UserModel(
        uid: user.uid,
        email: widget.user.email,
        alias: alias,
        photoUrl: _photoUrl,
        photoPublicId: widget.user.photoPublicId,
        gamesPlayed: widget.user.gamesPlayed,
        createdAt: widget.user.createdAt,
        age: age,
        gender: _selectedGender,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
        totalGames: widget.user.totalGames,
        totalQuestions: widget.user.totalQuestions,
        totalMinutes: widget.user.totalMinutes,
        partnerId: widget.user.partnerId,
        coupleId: widget.user.coupleId,
      );

      await UserService.updateUser(user.uid, updatedUser);

      // Mantener sincronizado el perfil de pareja (foto y nombre).
      await CoupleDataService.syncUserDataToCouple();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado exitosamente")),
      );

      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al actualizar: $e")));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Selecciona y sube una nueva foto de perfil.
  Future<void> _pickPhoto() async {
    try {
      final result = await PhotoService.pickAndUploadPhoto(context);
      if (result == null || !mounted) return;
      setState(() => _photoUrl = result.url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto seleccionada. Guarda los cambios.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al seleccionar foto: $e")));
    }
  }

  // Muestra un modal con opciones para cambiar o eliminar la foto.
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.of(context).border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_photoUrl.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: _pink,
                  ),
                  title: Text(
                    'Cambiar foto',
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Eliminar foto',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoUrl = '');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Foto eliminada. Guarda los cambios."),
                      ),
                    );
                  },
                ),
              ] else
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: _pink,
                  ),
                  title: Text(
                    'Seleccionar foto',
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye el formulario de edición de perfil.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.close, color: AppColors.of(context).textPrimary),
        ),
        title: Text(
          'Editar perfil',
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _loading ? null : _updateProfile,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _pink,
                    ),
                  )
                : const Text(
                    'Listo',
                    style: TextStyle(
                      color: _pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Foto de perfil centrada
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      ProfileAvatar(
                        size: 100,
                        imageUrl: _photoUrl.isNotEmpty ? _photoUrl : null,
                        fallbackText: widget.user.alias,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _pink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _showPhotoOptions,
                child: const Text(
                  'Cambiar foto',
                  style: TextStyle(
                    color: _pink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sección de información
              _buildTextField(
                controller: _aliasController,
                label: 'Nombre',

                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _ageController,
                label: 'Edad',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _buildDropdown(
                value: _selectedGender,
                label: 'Género',
                icon: Icons.wc_outlined,
                items: _genders,
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 14),

              _buildDropdown(
                value: _selectedMaritalStatus,
                label: 'Estado sentimental',
                icon: Icons.favorite_outline,
                items: _maritalStatuses,
                onChanged: (v) => setState(() => _selectedMaritalStatus = v),
              ),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _cityController,
                label: 'Ciudad',
                icon: Icons.location_city_outlined,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Campo de texto con estilo limpio.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);
    final iconColor = isLight
        ? AppColors.of(context).textSecondary
        : Colors.white54;
    final labelColor = isLight
        ? AppColors.of(context).textMuted
        : Colors.white.withValues(alpha: 0.4);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: AppColors.of(context).textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _pink,
      decoration: InputDecoration(
        filled: true,
        fillColor: isLight
            ? Colors.grey.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: _pink, fontSize: 18),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _pink, width: 1.7),
        ),
      ),
    );
  }

  // Dropdown con estilo limpio.
  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);
    final iconColor = isLight
        ? AppColors.of(context).textSecondary
        : Colors.white54;
    final labelColor = isLight
        ? AppColors.of(context).textMuted
        : Colors.white.withValues(alpha: 0.4);

    return DropdownButtonFormField<String>(
      initialValue: value,
      style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 15),
      dropdownColor: AppColors.of(context).surfaceAlt,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.of(context).textMuted,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isLight
            ? Colors.grey.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: .03),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: _pink, fontSize: 18),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _pink, width: 1.7),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(color: AppColors.of(context).textPrimary),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
