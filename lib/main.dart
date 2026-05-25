import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lovequiz_app/firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/game_setup_screen.dart';
import 'screens/game_play_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/premium_screen.dart';

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
      debugShowCheckedModeBanner: false, //quita el banner de debug
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

// Router configuration
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
  ],
);
