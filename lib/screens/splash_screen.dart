import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../config/app_bootstrap.dart';
import '../services/user_services.dart';
import '../features/notifications/services/fcm_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // True cuando la verificación de autenticación falla (p. ej. sin red):
  // muestra un estado de error con reintento en lugar de un spinner infinito.
  bool _failed = false;

  // Inicializa la verificación de autenticación al cargar la pantalla.
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Verifica si hay sesión activa y navega según el estado del perfil.
  void _checkAuth() async {
    setState(() => _failed = false);
    // Espera a que Firebase (lanzado en main) termine de inicializar, sin
    // bloquear el primer frame: la marca ya se está dibujando mientras tanto.
    try {
      await firebaseInitFuture;
    } catch (_) {
      // Si Firebase no está disponible, seguimos; el error real lo maneja el
      // flujo de autenticación de abajo.
    }
    // App Check (Play Integrity/App Attest) se activa sin bloquear la
    // navegación: los tokens se solicitan de forma perezosa y se refrescan
    // solos, así que el splash no debe esperar a la plataforma nativa.
    // En debug usa proveedores debug; en producción los reales.
    try {
      if (kDebugMode) {
        unawaited(
          FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          ),
        );
      } else {
        unawaited(FirebaseAppCheck.instance.activate());
      }
    } catch (_) {
      // Sin App Check disponible (p. ej. en tests) seguimos adelante.
    }
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Verificar si el usuario tiene perfil creado
        final hasProfile = await UserService.userProfileExists(user.uid);

        if (!mounted) return;

        if (hasProfile) {
          // Si la app se abrió desde una notificación de recuerdos, ir
          // directamente a esa pantalla en lugar del home.
          final initialRoute = FcmService.takeInitialRoute();
          if (initialRoute != null) {
            context.go(initialRoute);
          } else {
            // Si tiene perfil, ir al home
            context.go('/home');
          }
        } else {
          // Si no tiene perfil, ir a completar perfil
          context.go('/perfilRegister');
        }
      } else {
        if (!mounted) return;
        // Si no hay usuario, ir al login
        context.go('/login');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  // Muestra la marca de la app con una animación de entrada.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);

    return Scaffold(
      backgroundColor: ac.background,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, t, child) {
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: t, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.pink, AppColors.purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'LoveQuiz',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ac.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Juega con quien amas',
                style: TextStyle(color: ac.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 36),
              if (_failed)
                Column(
                  children: [
                    Text(
                      'No pudimos conectar. Revisá tu conexión e intentá de nuevo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ac.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _checkAuth,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                )
              else
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.pink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
