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
import '../utils/app_toast.dart';

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
class _PlayButton extends StatefulWidget {
  const _PlayButton();

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _startLoop();
  }

  void _startLoop() async {
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      await _shimmerCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/pairing'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── Base: the original button exactly as before ──
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 155),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.pink, AppColors.pinkGradientEnd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
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
                      const SizedBox(width: 12),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.pink,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Shimmer overlay: a diagonal white band that slides ──
                AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (context, _) {
                    final t = _shimmerCtrl.value;
                    final w = MediaQuery.sizeOf(context).width;
                    // Band slides from far-left to far-right
                    final dx = -w * 0.4 + (w * 1.4) * t;
                    return Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.rotate(
                            angle: -0.25,
                            child: Container(
                              width: w * 0.2,
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
  final ValueNotifier<int> _heartsListenable = ValueNotifier<int>(0);

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
      _heartsListenable.value = cachedStreak.hearts;
    }
    // Refresco silencioso desde Firestore
    final freshStreak = await AchievementService.refreshStreak();
    final freshStats = await AchievementService.refreshUserStats();
    if (mounted) {
      setState(() {
        _currentStreak = freshStreak.currentStreak;
        _totalQuestions = freshStats?['totalQuestions'] ?? 0;
      });
      _heartsListenable.value = freshStreak.hearts;
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

                    SizedBox(height: 4),

                    // Corazones de racha.
                    ValueListenableBuilder<int>(
                      valueListenable: _heartsListenable,
                      builder: (_, hearts, __) => Row(
                        children: List.generate(3, (i) {
                          final filled = i < hearts;
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Text(
                              filled ? '🤍' : '❤️',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
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
  String _coupleId = '';
  String _userName = '';
  String _partnerName = '';
  bool _isUser1 = true;
  bool _loadingCouple = true;

  @override
  void initState() {
    super.initState();
    _loadCouple();
  }

  Future<void> _loadCouple() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final user = await UserService.getUser(uid);
      if (!mounted || user == null) return;
      final couple = await CoupleDataService.getCoupleProfile();
      if (!mounted) return;
      if (couple != null && user.coupleId != null) {
        final partnerUid = couple.user1Id == uid
            ? couple.user2Id
            : couple.user1Id;
        final partner = await UserService.getUser(partnerUid);
        setState(() {
          _coupleId = user.coupleId!;
          _isUser1 = couple.user1Id == uid;
          _userName = user.alias.isNotEmpty ? user.alias : 'Yo';
          _partnerName = partner?.alias.isNotEmpty == true
              ? partner!.alias
              : 'Tu pareja';
          _loadingCouple = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[Home] _loadCouple error: $e');
    }
    if (mounted) setState(() => _loadingCouple = false);
  }

  /// Template sin personalizar: se guarda tal cual en Firestore para que
  /// ambos jugadores compartan la misma pregunta. El reemplazo de {partner}
  /// se hace solo al mostrar, nunca al almacenar.
  String get _rawQuestion {
    const fallback = "¿Cuál es tu recuerdo favorito juntos?";
    final pool = questionsData['romanticas'];
    if (pool == null || pool.isEmpty) return fallback;
    final days = DateTime.now().toUtc().difference(DateTime(2024, 1, 1)).inDays;
    return pool[days % pool.length];
  }

  String get _question {
    final name = _partnerName.isNotEmpty ? _partnerName : 'tu pareja';
    return _rawQuestion.replaceAll('{partner}', name);
  }

  bool get _isMyAnswer1 => _isUser1;

  void _openAnswerSheet(BuildContext context) {
    final controller = TextEditingController();
    final colors = AppColors.of(context);
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
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
              const SizedBox(height: 20),

              // ── Pregunta destacada ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.12),
                      AppColors.pink.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.pink.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: 18,
                          color: AppColors.pink,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pregunta del día',
                          style: TextStyle(
                            color: AppColors.pink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _question,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── TextField con borde y conteo ──
              TextField(
                controller: controller,
                maxLength: 300,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$currentLength/$maxLength',
                        style: TextStyle(
                          color: currentLength > 250
                              ? Colors.orange
                              : colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.pink.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Botones ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(
                          color: colors.textSecondary.withValues(alpha: .3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final answer = controller.text.trim();
                              if (answer.isEmpty) {
                                AppToast.showError(
                                  sheetContext,
                                  'Escribe una respuesta antes de guardar',
                                );
                                return;
                              }
                              setSheetState(() => saving = true);
                              try {
                                final couple =
                                    await CoupleDataService.getCoupleProfile();
                                if (couple == null || !sheetContext.mounted) {
                                  return;
                                }
                                await CoupleDataService.saveDailyAnswer(
                                  coupleId: couple.coupleId,
                                  question: _rawQuestion,
                                  answer: answer,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                  AppToast.showSuccess(
                                    context,
                                    '¡Respuesta guardada en tu historia!',
                                  );
                                }
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  AppToast.showError(
                                    sheetContext,
                                    'Error al guardar: $e',
                                  );
                                  setSheetState(() => saving = false);
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.pink.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.favorite_rounded, size: 18),
                      label: Text(saving ? 'Guardando...' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);

    // ── Sin pareja ──
    if (!_loadingCouple && _coupleId.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ac.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.favorite_border_rounded, size: 40, color: ac.textMuted),
            const SizedBox(height: 12),
            Text(
              'Enlaza tu pareja para responder juntos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ac.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ── Cargando ──
    if (_loadingCouple) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ac.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.pink,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<DailyAnswer?>(
      stream: CoupleDataService.todayAnswerStream(_coupleId),
      builder: (context, snapshot) {
        final today = snapshot.data;
        final myAnswer = _isMyAnswer1 ? today?.answer1 : today?.answer2;
        final hasAnswered = myAnswer != null;
        final bothAnswered = today?.bothAnswered ?? false;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: bothAnswered
                ? LinearGradient(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.08),
                      ac.surfaceAlt,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: bothAnswered ? null : ac.surfaceAlt,
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
              // ── Icono + título + badge ──
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pink.withValues(alpha: 0.15),
                          AppColors.pink.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Image.asset(
                      'lib/assets/images/icon_questionsOfDay.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pregunta del día',
                          style: TextStyle(
                            color: ac.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (bothAnswered)
                          Text(
                            'Ambos respondieron hoy',
                            style: TextStyle(
                              color: AppColors.pink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (hasAnswered)
                          Text(
                            'Ya respondiste',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Responde hoy',
                            style: TextStyle(
                              color: ac.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (bothAnswered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.pink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Listo',
                            style: TextStyle(
                              color: AppColors.pink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Pregunta ──
              Text(
                _question,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // ── Respuestas (si ambas existen) ──
              if (bothAnswered) ...[
                const SizedBox(height: 14),
                _buildAnswerPreview(
                  ac,
                  label: _userName,
                  answer: today!.answer1 ?? '',
                  isMe: _isMyAnswer1,
                ),
                const SizedBox(height: 8),
                _buildAnswerPreview(
                  ac,
                  label: _partnerName,
                  answer: today.answer2 ?? '',
                  isMe: !_isMyAnswer1,
                ),
              ],

              // ── Estado del partner (si solo yo respondí) ──
              if (hasAnswered && !bothAnswered) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_partnerName aún no responde',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Botón ──
              if (!hasAnswered)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _openAnswerSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Responder'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnswerPreview(
    AppColors ac, {
    required String label,
    required String answer,
    required bool isMe,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ac.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isMe
                ? AppColors.pink.withValues(alpha: 0.15)
                : Colors.blue.withValues(alpha: 0.15),
            child: Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.pink : Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ac.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '"$answer"',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: ac.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
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

            itemCount: 2,

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

                default:
                  return const SizedBox.shrink();
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

            border: Border.all(color: isLight ? ac.border : ac.borderLight),
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
