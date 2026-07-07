import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lovequiz_app/firebase_options.dart';
import 'package:lovequiz_app/screens/complete_profile_screens.dart';
import 'package:lovequiz_app/screens/history_detail_screen.dart';
import 'package:lovequiz_app/screens/history_screen.dart';
import 'package:lovequiz_app/screens/login_screen.dart';
import 'package:lovequiz_app/screens/perfil_screen.dart';
import 'package:lovequiz_app/screens/edit_profile_screen.dart';
import 'package:lovequiz_app/screens/settings_screen.dart';
import 'package:lovequiz_app/screens/splash_screen.dart';
import 'package:lovequiz_app/screens/main_tab_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/game_setup_screen.dart';
import 'screens/game_play_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/nuestra_historia_screen.dart';
import 'screens/social_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/ai_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LoveQuizApp());
}

class LoveQuizApp extends StatelessWidget {
  const LoveQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LoveQuiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(
      path: '/perfilRegister',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/editPerfil',
      builder: (context, state) {
        final user = state.extra as Map<String, dynamic>;
        return EditProfileScreen(user: user['user']);
      },
    ),

    GoRoute(path: '/home', builder: (context, state) => const MainTabScreen()),

    GoRoute(
      path: '/pairing',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        return PairingScreen(initialMode: mode);
      },
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return GameSetupScreen(
          mode: params['mode'] ?? 'local',
          p1: params['p1'] ?? 'Jugador 1',
          p2: params['p2'] ?? 'Jugador 2',
          roomCode: params['roomCode'],
          playerName: params['name'],
          isHost: params['host'] == 'true',
        );
      },
    ),
    GoRoute(
      path: '/play',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return GamePlayScreen(
          mode: params['mode'] ?? 'local',
          p1: params['p1'] ?? 'Jugador 1',
          p2: params['p2'] ?? 'Jugador 2',
          categories: (params['categories'] ?? '')
              .split(',')
              .where((c) => c.isNotEmpty)
              .toList(),
          timerSeconds: int.tryParse(params['timer'] ?? '0') ?? 0,
          totalQuestions: int.tryParse(params['totalQuestions'] ?? '30') ?? 30,
          roomCode: params['roomCode'],
          playerName: params['name'],
          isHost: params['host'] == 'true',
        );
      },
    ),
    GoRoute(
      path: '/waiting',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return WaitingRoomScreen(
          roomCode: params['roomCode'] ?? 'XXXXXX',
          playerName: params['name'] ?? 'Jugador',
          isHost: params['host'] == 'true',
          isRandom: params['random'] == 'true',
        );
      },
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/historyDetail',
      builder: (context, state) {
        final game = state.extra as Map<String, dynamic>;
        return HistoryDetailScreen(game: game);
      },
    ),

    // New routes
    GoRoute(
      path: '/nuestraHistoria',
      builder: (context, state) => const NuestraHistoriaScreen(),
    ),
    GoRoute(path: '/social', builder: (context, state) => const SocialScreen()),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(path: '/ai', builder: (context, state) => const AIScreen()),
  ],
);
