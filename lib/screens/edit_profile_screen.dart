import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lovequiz_app/services/user_services.dart';
import '../models/user_model.dart';

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
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

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
        photoUrl: widget.user.photoUrl,
        gamesPlayed: widget.user.gamesPlayed,
        createdAt: widget.user.createdAt,
        age: age,
        gender: _selectedGender,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
      );

      await UserService.updateUser(user.uid, updatedUser);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              ),
              const SizedBox(height: 30),

              // Alias (obligatorio)
              TextField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: "Alias *",
                  hintText: "Tu nombre de usuario",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Edad
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Edad",
                  hintText: "Ej: 25",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Género
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: "Género",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc_outlined),
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
                decoration: const InputDecoration(
                  labelText: "Ciudad",
                  hintText: "Tu ciudad de residencia",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Estado civil
              DropdownButtonFormField<String>(
                value: _selectedMaritalStatus,
                decoration: const InputDecoration(
                  labelText: "Estado Civil",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite_outline),
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
              const Text(
                "* Campos obligatorios",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: _loading ? null : _updateProfile,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Guardar cambios"),
                ),
              ),
              const SizedBox(height: 12),

              // Botón de cancelar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => context.pop(),
                  child: const Text("Cancelar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
