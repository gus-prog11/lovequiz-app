import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_colors.dart';
import '../config/app_bootstrap.dart';
import '../services/user_services.dart';
import '../services/saved_game.dart';
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
    // App Check se inicializa en main.dart ANTES de que el splash
    // screen se construya, garantizando que el token esté disponible
    // cuando las reglas lo requieran (isAppCheckValid).

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Verificar si el usuario tiene perfil creado
        final hasProfile = await UserService.userProfileExists(user.uid);

        if (!mounted) return;

        if (hasProfile) {
          // Verificar si hay una partida en curso para ofrecer reanudación.
          final saved = await SavedGame.load();
          if (saved != null && mounted) {
            // Verificar que la sala sigue existiendo y está en juego.
            final roomDoc = await FirebaseFirestore.instance
                .collection('rooms')
                .doc(saved.roomCode)
                .get();
            if (roomDoc.exists &&
                roomDoc.data()?['status'] == 'playing' &&
                mounted) {
              final resume = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Partida en curso'),
                  content: const Text(
                      'Tienes una partida incompleta. ¿Quieres reanudarla?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('No, salir'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Reanudar'),
                    ),
                  ],
                ),
              );
              if (resume == true && mounted) {
                SavedGame.save(saved);
                final params = <String, String>{
                  'mode': saved.mode,
                  'p1': saved.p1,
                  'p2': saved.p2,
                  'categories': saved.categories.join(','),
                  'timer': saved.timerSeconds.toString(),
                  'totalQuestions': saved.totalQuestions.toString(),
                  'roomCode': saved.roomCode,
                  'host': saved.isHost.toString(),
                };
                if (saved.playerName != null) params['name'] = saved.playerName!;
                context.go('/play?${Uri(queryParameters: params).query}');
                return;
              }
              // Si elige no reanudar, limpiar y continuar.
              await SavedGame.clear();
            } else {
              await SavedGame.clear();
            }
          }

          if (!mounted) return;
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
