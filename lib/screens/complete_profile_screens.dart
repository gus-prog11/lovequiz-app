import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lovequiz_app/services/user_services.dart';
import 'package:lovequiz_app/services/achievement_service.dart';
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
  void dispose() {
    _aliasController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

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
        photoUrl: '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Completa tu perfil")),
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

              // Botón de continuar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: _loading ? null : _saveProfile,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Continuar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
