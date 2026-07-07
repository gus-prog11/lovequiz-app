import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovequiz_app/services/user_services.dart';
import 'package:lovequiz_app/services/social_service.dart';
import 'package:lovequiz_app/services/achievement_service.dart';
import 'package:lovequiz_app/services/emotional_service.dart';
import 'package:lovequiz_app/models/user_model.dart';
import 'package:lovequiz_app/models/social_model.dart';
import 'package:lovequiz_app/models/achievement_model.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

const Color _fuchsia = Color(0xFFFF2E93);
const Color _darkBg = Color(0xFF0D0D0D);
const Color _purpleCard = Color(0xFF1A1A2E);

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
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF2D0A28), _darkBg],
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
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildHistorySection(),
                      const SizedBox(height: 20),
                      _buildAchievementsSection(),
                      const SizedBox(height: 24),
                      _buildPersonalInfo(),
                      const SizedBox(height: 24),
                      _buildSocialSection(),
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
          const Text("Mi Perfil",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: _fuchsia),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: _fuchsia),
                onPressed: () async {
                  if (user == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: user!)),
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
    final email = user?.email ?? "";
    final level = _calculateLevel();

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_fuchsia, const Color(0xFFF48FB1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: _fuchsia.withValues(alpha: 0.3), blurRadius: 16),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: _darkBg,
                    child: Icon(Icons.person, size: 44, color: Colors.white70),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _darkBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: _fuchsia),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(alias,
                  style: const TextStyle(color: _fuchsia, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              const Icon(Icons.favorite, color: _fuchsia, size: 16),
              const SizedBox(width: 2),
              const Icon(Icons.favorite, color: _fuchsia, size: 16),
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
                Text("Nivel Conversador $level",
                    style: const TextStyle(color: _fuchsia, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(email,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  // ─── III. Streak Card ─────────────────────────────────────────────────
  Widget _buildStreakCard() {
    final current = streak?.currentStreak ?? 0;
    final best = streak?.longestStreak ?? 0;
    final nextGoal = current < 3 ? 3 : (current < 7 ? 7 : (current < 14 ? 14 : 30));
    final level = _calculateLevel();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_fuchsia.withValues(alpha: 0.25), Colors.pink.shade900.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text("🔥", style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _streakColumn("Racha actual", "$current día", "¡Sigue así! 🔥"),
                const SizedBox(width: 16),
                _streakColumn("Mejor racha", "$best días", ""),
                const SizedBox(width: 16),
                _streakColumn("Próximo objetivo", "$nextGoal días", "para nivel $level"),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.amber, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _streakColumn(String title, String value, String subtitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9)),
          ],
        ],
      ),
    );
  }

  // ─── IV. Stats Row ────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final s = stats ?? GameStats();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: _purpleCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.sports_esports, "${s.totalGames}", "Partidas"),
          _statItem(Icons.question_mark, "${s.totalQuestions}", "Preguntas"),
          _statItem(Icons.timer, "${s.totalMinutes}h", "Minutos"),
          _statItem(Icons.group, "${s.totalFriends}", "Amigos"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _fuchsia, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
      ],
    );
  }

  // ─── V. Mi Historia & Logros ──────────────────────────────────────────
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.auto_awesome, "Mi historia en LoveQuiz"),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/nuestraHistoria'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _purpleCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _fuchsia.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.favorite, color: _fuchsia, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$_memoryCount recuerdos guardados",
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text("Cada momento cuenta en su historia juntos ❤️",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final total = AchievementModel.allAchievements.length;
    return GestureDetector(
      onTap: () => context.push('/achievements'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _purpleCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _fuchsia.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.emoji_events, color: _fuchsia, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Logros",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("$_unlockedAchievements/$total desbloqueados",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total > 0 ? _unlockedAchievements / total : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      color: _fuchsia,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _fuchsia, size: 16),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ─── VI. Personal Info ────────────────────────────────────────────────
  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.person, "Información personal"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _purpleCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _infoRow(Icons.cake, "Edad", user?.age != null ? "${user!.age} años" : "No especificado"),
              _divider(),
              _infoRow(Icons.wc, "Género", user?.gender ?? "No especificado"),
              _divider(),
              _infoRow(Icons.location_city, "Ciudad", user?.city ?? "No especificado"),
              _divider(),
              _infoRow(Icons.favorite, "Estado Civil", user?.maritalStatus ?? "No especificado"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _fuchsia, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Text(value,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 50);
  }

  // ─── VII. Social ──────────────────────────────────────────────────────
  Widget _buildSocialSection() {
    final friendCount = stats?.totalFriends ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.people, "Social"),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/social'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _purpleCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _fuchsia.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.people, color: _fuchsia, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Amigos e Invitaciones",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text("Invita a tus amigos y jueguen juntos",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(friendCount > 3 ? 3 : friendCount, (i) {
                            return Align(
                              widthFactor: 0.7,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: _fuchsia.withValues(alpha: 0.2),
                                child: const Icon(Icons.person, size: 14, color: Colors.white54),
                              ),
                            );
                          }),
                          if (friendCount > 3)
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _fuchsia.withValues(alpha: 0.1),
                              child: Text("+${friendCount - 3}",
                                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            ),
                          if (friendCount == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add, color: Colors.white38, size: 16),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.push('/social'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _purpleCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, color: _fuchsia, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text("$friendCount amigos",
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
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
