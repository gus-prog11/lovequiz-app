import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../services/user_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Verificar si el usuario tiene perfil creado
      final hasProfile = await UserService.userProfileExists(user.uid);

      if (!mounted) return;

      if (hasProfile) {
        // Si tiene perfil, ir al home
        context.go('/home');
      } else {
        // Si no tiene perfil, ir a completar perfil
        context.go('/perfilRegister');
      }
    } else {
      // Si no hay usuario, ir al login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
