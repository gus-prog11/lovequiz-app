import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/widgets/fade_slide_in.dart';
import 'package:LoveQuiz/widgets/pressable_scale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/questions.dart';
import '../models/couple_models.dart';
import '../services/achievement_service.dart';
import '../services/couple_data_service.dart';
import '../services/user_services.dart';
import '../screens/notifications_screen.dart';

// Permite a una sección del Home refrescar sus datos cuando la pestaña Inicio
// vuelve a ser la activa en MainTabScreen (las pantallas del IndexedStack no
// se reconstruyen al cambiar de pestaña).
mixin _RefreshOnTabVisible<T extends StatefulWidget> on State<T> {
  ValueListenable<int>? _tabIndex;
  bool _wasActive = true;

  void initTabRefresh(ValueListenable<int>? tabIndex) {
    _tabIndex = tabIndex;
    _wasActive = _tabIndex?.value == 0;
    _tabIndex?.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final isActive = _tabIndex!.value == 0;
    if (isActive && !_wasActive) refreshOnTabVisible();
    _wasActive = isActive;
  }

  void disposeTabRefresh() {
    _tabIndex?.removeListener(_onTabChanged);
  }

  Future<void> refreshOnTabVisible() async {}
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onGoToHistoria, this.tabIndex});

  // Permite saltar a la pestaña de Historia (recuerdos) desde esta pantalla
  // sin salir del MainTabScreen (la barra inferior queda visible).
  final VoidCallback? onGoToHistoria;

  // Notificador del tab seleccionado en MainTabScreen: al volver a la pestaña
  // Inicio las secciones refrescan sus datos (racha, alias) sin reconstruirse.
  final ValueListenable<int>? tabIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [AppColors.dark.surface, AppColors.dark.background]
                : [AppColors.light.surfaceAlt, AppColors.light.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Las secciones entran en cascada (fundido + deslizamiento).
                const FadeSlideIn(child: _Header()),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _WelcomeSection(tabIndex: tabIndex),
                ),
                const SizedBox(height: 16),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 120),
                  child: _PlayButton(),
                ),

                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: _StatsCard(tabIndex: tabIndex),
                ),
                const SizedBox(height: 18),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 240),
                  child: _QuestionOfTheDayCard(),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: _ContinueYourHistory(onTap: onGoToHistoria),
                ),
                const SizedBox(height: 20),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 360),
                  child: _AccesFast(),
                ),
                const SizedBox(height: 20),
                //  const _ProgressBanner(),
                // const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── A. Header ──────────────────────────────────────────────────────────────
class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  // La suscripción al conteo de no leídas se crea una vez por usuario y se
  // reutiliza entre builds: HomeScreen se reconstruye al cambiar de pestaña
  // (IndexedStack) y sin esta caché cada build abriría una nueva escucha.
  Stream<int>? _unreadStream;
  String? _streamUid;

  Stream<int>? _unreadCountStream(String uid) {
    if (_streamUid != uid) {
      _streamUid = uid;
      _unreadStream = NotificationHelper.unreadCountStream(uid);
    }
    return _unreadStream;
  }

  @override
  void dispose() {
    _unreadStream = null;
    _streamUid = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.pink, size: 18),
              const SizedBox(width: 6),
              Text(
                "LoveQuiz",
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          uid != null
              ? StreamBuilder<int>(
                  stream: _unreadCountStream(uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/notifications'),
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              : IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── B. Welcome + Heart ─────────────────────────────────────────────────────
class _WelcomeSection extends StatefulWidget {
  const _WelcomeSection({this.tabIndex});

  final ValueListenable<int>? tabIndex;

  @override
  State<_WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<_WelcomeSection>
    with _RefreshOnTabVisible<_WelcomeSection> {
  String _name = '';

  @override
  void initState() {
    super.initState();
    initTabRefresh(widget.tabIndex);
    _loadName();
  }

  @override
  void dispose() {
    disposeTabRefresh();
    super.dispose();
  }

  @override
  Future<void> refreshOnTabVisible() => _loadName();

  Future<void> _loadName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await UserService.getUser(uid);
    if (!mounted) return;
    setState(() => _name = user?.alias ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name.isNotEmpty ? 'Hola, $_name 👋' : 'Hola 👋',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: "Cada conversación\nfortalece su "),
                    TextSpan(
                      text: "historia 💗",
                      style: TextStyle(
                        color: AppColors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            Image.asset(
              'lib/assets/images/hearts_home.png',
              width: 220,
              height: 130,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── D. Play Button ─────────────────────────────────────────────────────────
class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/pairing'),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 155),

            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.pink, AppColors.pinkGradientEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

          child: Row(
            children: [
              // ❤️ Corazón
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // Texto
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "¿Listos para una nueva\nconversación?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Descubran algo nuevo juntos.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .70),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "JUGAR AHORA",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Flecha
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child:                 const Icon(
                  Icons.arrow_forward,
                  color: AppColors.pink,
                  size: 30,
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

// ─── C. Stats Row ───────────────────────────────────────────────────────────
class _StatsCard extends StatefulWidget {
  const _StatsCard({this.tabIndex});

  final ValueListenable<int>? tabIndex;

  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard>
    with _RefreshOnTabVisible<_StatsCard> {
  int _currentStreak = 0;
  int _totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    initTabRefresh(widget.tabIndex);
    _loadStats();
  }

  @override
  void dispose() {
    disposeTabRefresh();
    super.dispose();
  }

  @override
  Future<void> refreshOnTabVisible() => _loadStats();

  /// Carga racha y estadísticas usando caché primero, luego refresca.
  Future<void> _loadStats() async {
    // Carga inmediata desde caché
    final cachedStreak = await AchievementService.getStreak();
    final cachedStats = await AchievementService.getUserStats();
    if (mounted) {
      setState(() {
        _currentStreak = cachedStreak.currentStreak;
        _totalQuestions = cachedStats?['totalQuestions'] ?? 0;
      });
    }
    // Refresco silencioso desde Firestore
    final freshStreak = await AchievementService.refreshStreak();
    final freshStats = await AchievementService.refreshUserStats();
    if (mounted) {
      setState(() {
        _currentStreak = freshStreak.currentStreak;
        _totalQuestions = freshStats?['totalQuestions'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(70, 14, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.of(context).surfaceAlt,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(width: 16),

              /// Lado izquierdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Racha actual",
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      _currentStreak == 0
                          ? "0 días"
                          : "$_currentStreak ${_currentStreak == 1 ? 'día' : 'días'}",
                      style: TextStyle(
                        color: AppColors.pink,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      "¡Sigue así! 🔥",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 120,
                color: AppColors.of(context).divider,
              ),

              SizedBox(width: 20),

              /// Lado derecho
              SizedBox(
                width: 70,
                child: _StatCircle(
                  asset: 'lib/assets/images/icon_mensage.png',
                  imageSize: 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Preguntas respondidas",
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "$_totalQuestions",
                      style: TextStyle(
                        color: AppColors.pink,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Sigan así, lo están haciendo genial.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 60,
          child: _StatCircle(asset: 'lib/assets/images/icon_racha.png'),
        ),
      ],
    );
  }
}

/// Círculo decorativo de las tarjetas de estadísticas (racha y mensaje).
///
/// Comparte gradiente, sombra y borde rosa entre ambos badges; solo cambia la
/// imagen y su ajuste. Antes el decorado se duplicaba en dos contenedores.
class _StatCircle extends StatelessWidget {
  const _StatCircle({
    required this.asset,
    this.imageSize = 50,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double imageSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: .25),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
        gradient: RadialGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Color(0xFF3D1730), Color(0xFF181220)]
              : [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
        ),
        border: Border.all(
          color: AppColors.pink.withValues(alpha: .6),
          width: 2,
        ),
      ),
      child: Image.asset(asset, width: imageSize, height: imageSize, fit: fit),
    );
  }
}

// ───Question of the Day Card ─────────────────────────────────────────────────────

class _QuestionOfTheDayCard extends StatefulWidget {
  const _QuestionOfTheDayCard();

  @override
  State<_QuestionOfTheDayCard> createState() => _QuestionOfTheDayCardState();
}

class _QuestionOfTheDayCardState extends State<_QuestionOfTheDayCard> {
  // Pregunta determinista del día: gira por el banco de preguntas según la fecha.
  String get _question {
    const fallback = "¿Cuál es tu recuerdo favorito juntos?";
    final pool = questionsData['romanticas'];
    if (pool == null || pool.isEmpty) return fallback;
    final days = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return pool[days % pool.length];
  }

  void _openAnswerSheet(BuildContext context) {
    final controller = TextEditingController();
    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Pregunta del día",
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _question,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: "Escribe tu respuesta para compartirla con tu pareja...",
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.textSecondary.withValues(alpha: .4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cerrar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final answer = controller.text.trim();
                      if (answer.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Escribe una respuesta para guardarla en su historia",
                            ),
                          ),
                        );
                        return;
                      }
                      final couple = await CoupleDataService.getCoupleProfile();
                      if (couple == null || !sheetContext.mounted) return;
                      await CoupleDataService.saveDailyAnswer(
                        coupleId: couple.coupleId,
                        question: _question,
                        answer: answer,
                      );
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Guardada en su historia"),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text("Guardar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icono + título
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.pink.withValues(alpha: .15)
                      : AppColors.of(
                          context,
                        ).textSecondary.withValues(alpha: .12),
                ),
                child: Image.asset("lib/assets/images/icon_questionsOfDay.png"),
              ),

              const SizedBox(width: 14),

              Text(
                "Pregunta del día",
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _question,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 17,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _openAnswerSheet(context),

              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.pink.withValues(alpha: .5)),

                foregroundColor: AppColors.pink,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),

              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text("Responder"),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ContinueYourHistory ───────────────────────────────────────────────────────────
class _ContinueYourHistory extends StatelessWidget {
  const _ContinueYourHistory({this.onTap});

  // Al tocarlo lleva a la pestaña de Historia (con sus recuerdos) sin salir
  // del MainTabScreen, de modo que la barra inferior sigue visible.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CoupleProfile?>(
      stream: CoupleDataService.coupleProfileStream(),
      builder: (context, profileSnapshot) {
        final coupleId = profileSnapshot.data?.coupleId ?? '';
        if (coupleId.isEmpty) {
          return _buildCard(
            context: context,
            photoUrls: const [],
            memoryCount: 0,
          );
        }

        return StreamBuilder<List<Memory>>(
          stream: CoupleDataService.memoriesStream(coupleId),
          builder: (context, memorySnapshot) {
            final memories = memorySnapshot.data ?? [];

            // Las últimas tres fotos entre todos los recuerdos (los recuerdos
            // vienen ordenados por fecha, los más recientes primero).
            final photoUrls = <String>[];
            for (final memory in memories) {
              for (final url in memory.photoUrls) {
                if (photoUrls.length == 3) break;
                photoUrls.add(url);
              }
              if (photoUrls.length == 3) break;
            }

            return _buildCard(
              context: context,
              photoUrls: photoUrls,
              memoryCount: memories.length,
            );
          },
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required List<String> photoUrls,
    required int memoryCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.of(context).surfaceAlt,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            // Cuando hay fotos se muestran las últimas tres superpuestas como
            // historias de Instagram; si aún no hay, se mantiene el icono.
            photoUrls.isNotEmpty
                ? _buildStoryPhotos(photoUrls)
                : const Icon(
                    Icons.heart_broken,
                    color: AppColors.warning,
                    size: 26,
                  ),
            const SizedBox(width: 16),

            /// Lado izquierdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Continúa su historia",
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 2),

                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.of(context).textPrimary,
                      ),
                      children: [
                        TextSpan(text: "Tienen "),
                        TextSpan(
                          text: "$memoryCount recuerdos ",
                          style: TextStyle(color: AppColors.pink),
                        ),
                        TextSpan(
                          text: memoryCount == 1 ? "guardado" : "guardados",
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Sigan creando momentos inolvidables",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 20),

            /// Lado derecho
            Icon(Icons.arrow_right_alt, color: AppColors.purple, size: 26),
            SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  // Apila las fotos una sobre otra: cada una es un cuadro grande con bordes
  // redondeados, como las historias de Instagram pero sin anillo de color.
  Widget _buildStoryPhotos(List<String> photoUrls) {
    const size = 56.0;
    const overlap = 36.0;
    final totalWidth = size + (photoUrls.length - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(photoUrls.length, (index) {
          return Positioned(
            left: index * (size - overlap),
            child: _buildStoryRing(photoUrls[index]),
          );
        }),
      ),
    );
  }

  Widget _buildStoryRing(String photoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 56,
        height: 56,
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => ColoredBox(
            color: Colors.white,
            child: Center(child: Icon(Icons.image, color: AppColors.pink)),
          ),
        ),
      ),
    );
  }
}

// ─── Acceso Rapido     ─────────────────────────────────────────────────────
class _AccesFast extends StatelessWidget {
  const _AccesFast();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Accesos rápidos",
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),

            itemCount: 4,

            separatorBuilder: (_, __) => const SizedBox(width: 14),

            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return SizedBox(
                    width: 145,
                    child: _QuickCard(
                      route: "/nuestraHistoria",
                      title: "Historia",
                      subtitle: "Recuerdos y\nmomentos",
                      image: Image.asset(
                        "lib/assets/images/icon_history.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      imageColor: AppColors.pink,
                      startColor: const Color(0xFF511B39),
                      endColor: const Color(0xFF261320),
                    ),
                  );

                case 1:
                  return SizedBox(
                    width: 145,
                    child: _QuickCard(
                      route: "/achievements",
                      title: "Logros",
                      subtitle: "Desbloquea y\nsigue tu progreso",
                      image: Image.asset(
                        "lib/assets/images/icon_logros.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      imageColor: AppColors.warning,
                      startColor: const Color(0xFF4A2913),
                      endColor: const Color(0xFF261813),
                    ),
                  );

                case 2:
                  return SizedBox(
                    width: 145,
                    child: _QuickCard(
                      route: "/ai",
                      title: "LoveQuiz IA",
                      subtitle: "Preguntas\npersonalizadas",
                      image: Image.asset(
                        "lib/assets/images/icon_ia.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      imageColor: AppColors.purple,
                      startColor: const Color(0xFF321A57),
                      endColor: const Color(0xFF1D1531),
                    ),
                  );

                default:
                  return SizedBox(
                    width: 145,
                    child: _QuickCard(
                      route: "/premium",
                      title: "Premium",
                      subtitle: "Desbloquea todo\nel potencial",
                      image: Image.asset(
                        "lib/assets/images/icon_premium.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      imageColor: AppColors.cyan,
                      startColor: const Color(0xFF19345E),
                      endColor: const Color(0xFF16233E),
                    ),
                  );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final Image image;
  final String title;
  final String subtitle;

  final Color imageColor;
  final Color startColor;
  final Color endColor;
  final String route;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.imageColor,
    required this.startColor,
    required this.endColor,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final ac = AppColors.of(context);

    return PressableScale(
      child: GestureDetector(
        onTap: () => context.push(route),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),

            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [ac.background, ac.surfaceAlt]
                  : [startColor, endColor],
            ),

            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],

            border: Border.all(
              color: isLight ? ac.border : ac.borderLight,
            ),
          ),

        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLight
                    ? ac.textSecondary.withValues(alpha: .15)
                    : imageColor.withValues(alpha: .15),

                boxShadow: isLight
                    ? []
                    : [
                        BoxShadow(
                          color: imageColor.withValues(alpha: .25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
              ),

              child: Center(child: image),
            ),

            const Spacer(),

            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
