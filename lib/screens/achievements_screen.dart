import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/models/achievement_model.dart';
import 'package:LoveQuiz/services/achievement_service.dart';
import 'package:LoveQuiz/services/premium_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final premium = await PremiumService.getPremiumStatus();
    if (mounted) setState(() => _isPremium = premium.isPremium);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        title: Text(
          'Logros',
          style: TextStyle(
            color: ac.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.pink,
          labelColor: AppColors.pink,
          unselectedLabelColor: ac.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Logros'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Rachas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AchievementsTab(isPremium: _isPremium),
          const _StreaksTab(),
        ],
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  final bool isPremium;
  const _AchievementsTab({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AchievementService.achievementsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final userAchievements = <String, UserAchievement>{};
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final a = UserAchievement.fromMap(
              doc.data() as Map<String, dynamic>,
            );
            userAchievements[a.achievementId] = a;
          }
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: AchievementModel.allAchievements.length,
          itemBuilder: (context, index) {
            final a = AchievementModel.allAchievements[index];
            final userA = userAchievements[a.id];
            final progress = userA?.progress ?? 0;
            final unlocked = userA?.unlocked ?? false;
            final isLockedPremium = a.isPremium && !isPremium;
            final ac = AppColors.of(context);
            final isLight = Theme.of(context).brightness == Brightness.light;
            return Opacity(
              opacity: unlocked ? 1.0 : (isLockedPremium ? 0.4 : 0.7),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ac.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ac.border),
                  boxShadow: isLight
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                    children: [
                      Text(a.icon, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (a.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.pink.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'PREMIUM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.pink,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: ac.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!unlocked)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (progress / a.targetProgress)
                                          .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      color: AppColors.pink,
                                      backgroundColor: ac.surfaceAlt,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$progress/${a.targetProgress}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ac.textMuted,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '¡Desbloqueado!',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (userA?.unlockedAt != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${userA!.unlockedAt!.day}/${userA.unlockedAt!.month}/${userA.unlockedAt!.year}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ac.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            if (isLockedPremium)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Desbloquea Premium para acceder',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.pink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StreaksTab extends StatefulWidget {
  const _StreaksTab();

  @override
  State<_StreaksTab> createState() => _StreaksTabState();
}

class _StreaksTabState extends State<_StreaksTab> {
  StreakData? _streak;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await AchievementService.getStreak();
    if (mounted) {
      setState(() {
        _streak = streak;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final ac = AppColors.of(context);
    final streak = _streak!;
    final milestones = [3, 7, 14, 30, 60, 100];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.pink, AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  '${streak.currentStreak}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'días seguidos',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mejor racha: ${streak.longestStreak} días',
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
              ],
            ),
          ),
          if (streak.lastPlayDate != null) ...[
            const SizedBox(height: 16),
            Text(
              'Última partida: ${streak.lastPlayDate!.day}/${streak.lastPlayDate!.month}/${streak.lastPlayDate!.year}',
              style: TextStyle(color: ac.textSecondary),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Metas de Racha',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...milestones.map(
            (m) => _milestoneRow(
              days: m,
              achieved: streak.longestStreak >= m,
              current: streak.currentStreak >= m,
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneRow({
    required int days,
    required bool achieved,
    required bool current,
  }) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final icons = {3: '🥉', 7: '🥈', 14: '🌙', 30: '🔥', 60: '💪', 100: '👑'};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.border),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Text(
          icons[days] ?? '🎯',
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          '$days días seguidos',
          style: TextStyle(color: ac.textPrimary),
        ),
        trailing: achieved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : (current
                  ? const Text(
                      '¡En progreso!',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    )
                  : Text(
                      '$days',
                      style: TextStyle(color: ac.textMuted),
                    )),
      ),
    );
  }
}
