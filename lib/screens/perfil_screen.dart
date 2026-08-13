import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/models/achievement_model.dart';
import 'package:LoveQuiz/models/social_model.dart';
import 'package:LoveQuiz/models/user_model.dart';
import 'package:LoveQuiz/services/achievement_service.dart';
import 'package:LoveQuiz/services/couple_data_service.dart';
import 'package:LoveQuiz/services/emotional_service.dart';
import 'package:LoveQuiz/services/photo_service.dart';
import 'package:LoveQuiz/services/social_service.dart';
import 'package:LoveQuiz/services/user_services.dart';
import 'package:LoveQuiz/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

const Color _fuchsia = Color(0xFFFF2E93);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? user;
  GameStats? stats;
  StreakData? streak;
  int _unlockedAchievements = 0;
  int _memoryCount = 0;
  bool loading = true;
  bool _photoUploading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final results = await Future.wait([
      UserService.getUser(currentUser.uid),
      SocialService.getGameStats(),
      AchievementService.getStreak(),
      EmotionalService.getMemories(),
    ]);

    final u = results[0] as UserModel?;
    final s = results[1] as GameStats;
    final st = results[2] as StreakData;
    final mems = results[3] as List;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('achievements')
        .where('unlocked', isEqualTo: true)
        .get();
    final unlocked = snap.docs.length;

    if (!mounted) return;
    setState(() {
      user = u;
      stats = s;
      streak = st;
      _unlockedAchievements = unlocked;
      _memoryCount = mems.length;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.of(context).surface,
              AppColors.of(context).background,
            ],
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: _fuchsia))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      _buildStreakCard(),
                      const SizedBox(height: 20),

                      _buildHistorySection(),

                      const SizedBox(height: 24),
                      _buildPersonalInfo(),
                      const SizedBox(height: 24),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── I. Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Mi Perfil",
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: _fuchsia),
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 280),
                    reverseTransitionDuration: const Duration(milliseconds: 240),
                    pageBuilder: (_, animation, secondaryAnimation) =>
                        const SettingsScreen(),
                    transitionsBuilder: (
                      _,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).chain(
                        CurveTween(curve: Curves.easeOutCubic),
                      ).animate(animation);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: _fuchsia),
                onPressed: () async {
                  if (user == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: user!),
                    ),
                  );
                  if (mounted) loadData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── II. Profile Card ─────────────────────────────────────────────────
  Widget _buildProfileCard() {
    final alias = user?.alias ?? "Usuario";
    final level = _calculateLevel();
    final photoUrl = user?.photoUrl ?? '';

    return Center(
      child: Column(
        children: [
          ProfileAvatar(
            size: 110,
            imageUrl: photoUrl.isNotEmpty ? photoUrl : null,
            fallbackText: alias,
            borderColor: Colors.white,
            borderWidth: 3,
            boxShadow: [
              BoxShadow(color: _fuchsia.withValues(alpha: 0.3), blurRadius: 16),
            ],
            badge: GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  shape: BoxShape.circle,
                ),
                child: _photoUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _fuchsia,
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 16, color: _fuchsia),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                alias,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: _fuchsia.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: _fuchsia, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Nivel Conversador $level",
                  style: const TextStyle(
                    color: _fuchsia,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── III. Streak Card ─────────────────────────────────────────────────
  Widget _buildStreakCard() {
    final s = stats ?? GameStats();
    final current = streak?.currentStreak ?? 0;

    return Column(
      children: [
        _sectionHeader(Icons.graphic_eq_rounded, "Mi progreso"),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _fuchsia.withValues(alpha: 0.28),
                _fuchsia.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.asset(
                "lib/assets/images/icon_racha.png",
                height: 60,
                width: 60,
              ),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _streakColumn(
                      "Racha actual",
                      "$current día",
                      "¡Sigue así! 🔥",
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: AppColors.of(context).border,
                    ),

                    _statItem(
                      Icons.sports_esports,
                      "${s.totalGames}",
                      "Partidas",
                    ),
                    _statItem(
                      Icons.question_mark,
                      "${s.totalQuestions}",
                      "Preguntas",
                    ),
                    _statItem(Icons.timer, "${s.totalMinutes}h", "Minutos"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _streakColumn(String title, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _fuchsia, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ─── V. Mi Historia & Logros ──────────────────────────────────────────
  Widget _buildHistorySection() {
    final total = AchievementModel.allAchievements.length;

    return Column(
      children: [
        _sectionHeader(Icons.auto_awesome, "Mi historia en LoveQuiz"),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _fuchsia.withValues(alpha: 0.28),
                _fuchsia.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _fuchsia.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: _fuchsia,
                        size: 24,
                      ),
                    ),
                    Text(
                      "Recuerdos",
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$_memoryCount guardados",
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontSize: 11,
                      ),
                    ),

                    IconButton(
                      onPressed: () => context.push('/nuestraHistoria'),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.of(context).textMuted,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.of(context).border,
              ),

              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _fuchsia.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: _fuchsia,
                        size: 24,
                      ),
                    ),
                    Text(
                      "Logros",
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$_unlockedAchievements/$total desbloqueados",
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontSize: 11,
                      ),
                    ),

                    IconButton(
                      onPressed: () => context.push('/achievements'),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.of(context).textMuted,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.of(context).border,
              ),

              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _fuchsia.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: _fuchsia,
                        size: 24,
                      ),
                    ),
                    Text(
                      "Actividad",
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$_memoryCount guardados",
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontSize: 11,
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.of(context).textMuted,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _fuchsia, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── VI. Personal Info ────────────────────────────────────────────────
  Future<void> _openEditProfile() async {
    final current = user;
    if (current == null) return;
    await context.push('/editPerfil', extra: {'user': current});
    if (mounted) loadData();
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.person, "Información personal"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _infoRow(
                Icons.cake,
                "Edad",
                user?.age != null ? "${user!.age} años" : "No especificado",
                onTap: _openEditProfile,
              ),
              _divider(),
              _infoRow(
                Icons.wc,
                "Género",
                user?.gender ?? "No especificado",
                onTap: _openEditProfile,
              ),
              _divider(),
              _infoRow(
                Icons.location_city,
                "Ciudad",
                user?.city ?? "No especificado",
                onTap: _openEditProfile,
              ),
              _divider(),
              _infoRow(
                Icons.favorite,
                "Estado Civil",
                user?.maritalStatus ?? "No especificado",
                onTap: _openEditProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _fuchsia, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              onTap == null ? Icons.lock_outline : Icons.chevron_right,
              color: AppColors.of(context).textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: AppColors.of(context).border, indent: 50);
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_photoUploading) return;
    setState(() => _photoUploading = true);
    try {
      final result = await PhotoService.pickAndUploadPhoto(context);
      if (result == null || !mounted) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await UserService.updatePhoto(uid, result.url, result.publicId);
      await CoupleDataService.syncUserDataToCouple();
      if (!mounted) return;

      setState(() {
        user = user?.copyWith(
          photoUrl: result.url,
          photoPublicId: result.publicId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto de perfil actualizada")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al subir foto: $e")));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  void _showPhotoOptions() {
    final photoUrl = user?.photoUrl ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Foto de perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (photoUrl.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: _PhotoOptionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Cambiar foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto();
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _PhotoOptionButton(
                  icon: Icons.delete_outline,
                  label: 'Eliminar foto',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _deletePhoto();
                  },
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: _PhotoOptionButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Seleccionar foto',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadPhoto();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _photoUploading = true);
    try {
      await UserService.updatePhotoUrl(uid, '');
      await CoupleDataService.syncUserDataToCouple();
      if (!mounted) return;

      setState(() {
        user = user?.copyWith(photoUrl: '');
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Foto eliminada")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al eliminar foto: $e")));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  int _calculateLevel() {
    final totalQuestions = stats?.totalQuestions ?? 0;
    if (totalQuestions >= 500) return 10;
    if (totalQuestions >= 300) return 9;
    if (totalQuestions >= 200) return 8;
    if (totalQuestions >= 100) return 7;
    if (totalQuestions >= 50) return 6;
    if (totalQuestions >= 25) return 5;
    if (totalQuestions >= 10) return 4;
    if (totalQuestions >= 5) return 3;
    if (totalQuestions >= 2) return 2;
    return 1;
  }
}

class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.of(context).textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
