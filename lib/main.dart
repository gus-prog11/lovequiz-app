import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/firebase_options.dart';
import 'package:LoveQuiz/screens/complete_profile_screens.dart';
import 'package:LoveQuiz/screens/edit_profile_screen.dart';
import 'package:LoveQuiz/screens/history_detail_screen.dart';
import 'package:LoveQuiz/screens/history_screen.dart';
import 'package:LoveQuiz/screens/login_screen.dart';
import 'package:LoveQuiz/screens/main_tab_screen.dart';
import 'package:LoveQuiz/screens/perfil_screen.dart';
import 'package:LoveQuiz/screens/settings_screen.dart';
import 'package:LoveQuiz/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/pairing_screen.dart';
import 'screens/game_setup_screen.dart';
import 'screens/game_play_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/historia_screen.dart';
import 'screens/social_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/notifications_screen.dart';
import 'features/game_engine/screens/engine_test_screen.dart';
import 'features/voice_memories/screens/voice_demo_screen.dart';
import 'features/voice_memories/screens/voice_memories_screen.dart';
import 'features/notifications/services/fcm_service.dart';
import 'config/beta_config.dart';
import 'services/premium_service.dart';
import 'package:intl/date_symbol_data_local.dart';

// Punto de entrada de la aplicación: inicializa Firebase y lanza el widget raíz.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('es_ES');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notificaciones FCM. En modo beta (sin Firebase Blaze) quedan
  // deshabilitadas; el servicio FcmService permanece intacto y se activa
  // cuando BetaConfig.notificationsEnabled sea true (ver
  // lib/config/beta_config.dart). La captura de la ruta inicial desde una
  // notificación es parte de ese bloque: en beta no hay push que atender.
  if (BetaConfig.notificationsEnabled) {
    await FcmService.instance.init(
      onOpenVoiceMemories: () => router.go('/voice-memories'),
    );
  }
  final savedMode = await PremiumService.getSavedThemeMode();
  PremiumService.themeModeNotifier.value = savedMode;
  runApp(LoveQuizApp());
}

MediaQuery _responsiveTextScale(BuildContext context, Widget? child) {
  final media = MediaQuery.of(context);
  // Escala de accesibilidad del sistema, SIN caparla: usuarios con fuentes
  // grandes (>1.25×) deben ver el texto a su tamaño, no al límite de la app.
  final userFactor = media.textScaler.scale(14) / 14.0;
  // Ajuste sutil por ancho de pantalla (dispositivos grandes).
  final deviceFactor = (media.size.width / 375.0).clamp(1.0, 1.2).toDouble();
  final total = (userFactor * deviceFactor).clamp(0.9, double.infinity).toDouble();
  return MediaQuery(
    data: media.copyWith(textScaler: TextScaler.linear(total)),
    child: child ?? const SizedBox.shrink(),
  );
}

// Widget raíz de la app que configura los temas y el router de navegación.
class LoveQuizApp extends StatefulWidget {
  const LoveQuizApp({super.key});

  @override
  State<LoveQuizApp> createState() => _LoveQuizAppState();
}

class _LoveQuizAppState extends State<LoveQuizApp> {
  @override
  void initState() {
    super.initState();
    PremiumService.themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    PremiumService.themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LoveQuiz',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          _responsiveTextScale(context, _ThemeVeil(child: child!)),
      // Tema claro con branding rosa mode Instagram/Facebook.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.pink,
          brightness: Brightness.light,
          surface: const Color(0xFFFBF1F4),
        ),
        scaffoldBackgroundColor: AppColors.light.background,
        fontFamily: 'Roboto',
        extensions: const [AppColors.light],
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.light.surface,
          foregroundColor: AppColors.light.textPrimary,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.light.surfaceAlt,
          labelStyle: TextStyle(color: AppColors.light.textSecondary),
          hintStyle: TextStyle(color: AppColors.light.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.light.surface,
          contentTextStyle: TextStyle(color: AppColors.light.textPrimary),
        ),
      ),
      // Tema oscuro (diseño actual de la app).
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.pink,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.dark.background,
        fontFamily: 'Roboto',
        extensions: const [AppColors.dark],
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.dark.surface,
          foregroundColor: AppColors.dark.textPrimary,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.dark.surfaceAlt,
          labelStyle: TextStyle(color: AppColors.dark.textSecondary),
          hintStyle: TextStyle(color: AppColors.dark.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.dark.surface,
          contentTextStyle: TextStyle(color: AppColors.dark.textPrimary),
        ),
      ),
      themeMode: PremiumService.themeModeNotifier.value,
      // La interpolación interna de ThemeData no es fluida (brightness salta a
      // mitad de la animación); el cambio se hace instantáneo bajo el velo.
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
    );
  }
}

// Configuración de rutas de navegación con GoRouter.
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // Pantalla de splash al iniciar la app.
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    // Pantalla de inicio de sesión.
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // Pantalla para completar el perfil después del registro.
    GoRoute(
      path: '/perfilRegister',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    // Pantalla de perfil del usuario.
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const ProfileScreen(),
    ),
    // Pantalla \de edición de perfil.
    GoRoute(
      path: '/editPerfil',
      builder: (context, state) {
        final user = state.extra as Map<String, dynamic>;
        return EditProfileScreen(user: user['user']);
      },
    ),

    // Pantalla principal con tabs de navegación.
    GoRoute(path: '/home', builder: (context, state) => const MainTabScreen()),

    // Pantalla de emparejamiento de pareja.
    GoRoute(
      path: '/pairing',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        return PairingScreen(initialMode: mode);
      },
    ),
    // Pantalla de configuración antes de jugar.
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
    // Pantalla de juego activo con preguntas.
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
    // Sala de espera para partidas en línea.
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
    // Pantalla de suscripción premium.
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    // Pantalla de configuración general.
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    ),
    // Pantalla de historial de partidas jugadas.
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    // Pantalla con el detalle de una partida específica.
    GoRoute(
      path: '/historyDetail',
      builder: (context, state) {
        final game = state.extra as Map<String, dynamic>;
        return HistoryDetailScreen(game: game);
      },
    ),

    // Rutas adicionales de funcionalidades sociales y premium.
    // Pantalla de la historia compartida de la pareja.
    GoRoute(
      path: '/nuestraHistoria',
      builder: (context, state) => const HistoriaScreen(),
    ),
    // Pantalla de red social de amigos.
    GoRoute(path: '/social', builder: (context, state) => const SocialScreen()),
    // Pantalla de logros del usuario.
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    // Pantalla de asistente con inteligencia artificial.
    GoRoute(path: '/ai', builder: (context, state) => const AIScreen()),
    // Demo de grabación de voz (solo desarrollo).
    if (kDebugMode)
      GoRoute(
        path: '/voice-demo',
        builder: (context, state) => const VoiceDemoScreen(),
      ),
    // Partida de prueba del nuevo motor (solo desarrollo). Paralela al juego
    // legacy: no reemplaza el flujo actual.
    if (kDebugMode)
      GoRoute(
        path: '/engine-test',
        builder: (context, state) => const EngineTestScreen(),
      ),
    // Historial de recuerdos de voz de la pareja.
    GoRoute(
      path: '/voice-memories',
      builder: (context, state) => const VoiceMemoriesScreen(),
    ),
    // Pantalla de notificaciones del usuario.
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

// Velo de transición de tema: al cambiar entre modo claro y oscuro superpone
// un fondo del color anterior y lo desvanece, haciendo el cambio suave y
// fluido en lugar de un salto brusco.
class _ThemeVeil extends StatefulWidget {
  const _ThemeVeil({required this.child});

  final Widget child;

  @override
  State<_ThemeVeil> createState() => _ThemeVeilState();
}

class _ThemeVeilState extends State<_ThemeVeil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Color _veilColor = Colors.transparent;
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
    _dark = _isDark();
    _veilColor = _dark ? AppColors.dark.background : AppColors.light.background;
    PremiumService.themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    PremiumService.themeModeNotifier.removeListener(_onThemeChanged);
    _controller.dispose();
    super.dispose();
  }

  bool _isDark() {
    final mode = PremiumService.themeModeNotifier.value;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _onThemeChanged() {
    final newDark = _isDark();
    if (newDark == _dark) return;
    setState(() {
      _veilColor = _dark
          ? AppColors.dark.background
          : AppColors.light.background;
      _dark = newDark;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
            child: ColoredBox(color: _veilColor),
          ),
        ),
      ],
    );
  }
}
