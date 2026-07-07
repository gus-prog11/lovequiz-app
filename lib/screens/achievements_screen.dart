import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovequiz_app/models/achievement_model.dart';
import 'package:lovequiz_app/services/achievement_service.dart';
import 'package:lovequiz_app/services/premium_service.dart';

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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
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
            final a = UserAchievement.fromMap(doc.data() as Map<String, dynamic>);
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
            return Opacity(
              opacity: unlocked ? 1.0 : (isLockedPremium ? 0.4 : 0.7),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                  child: Text(a.title,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                if (a.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('PREMIUM',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(a.description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 8),
                            if (!unlocked)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (progress / a.targetProgress).clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$progress/${a.targetProgress}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  const SizedBox(width: 4),
                                  const Text('¡Desbloqueado!',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  if (userA?.unlockedAt != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${userA!.unlockedAt!.day}/${userA.unlockedAt!.month}/${userA.unlockedAt!.year}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            if (isLockedPremium)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Desbloquea Premium para acceder',
                                    style: TextStyle(fontSize: 11, color: Colors.amber.shade700)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    if (mounted) setState(() {
      _streak = streak;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
              gradient: LinearGradient(
                colors: [Colors.deepOrange.shade300, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('${streak.currentStreak}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('días seguidos', style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Mejor racha: ${streak.longestStreak} días',
                    style: const TextStyle(fontSize: 14, color: Colors.white60)),
              ],
            ),
          ),
          if (streak.lastPlayDate != null) ...[
            const SizedBox(height: 16),
            Text('Última partida: ${streak.lastPlayDate!.day}/${streak.lastPlayDate!.month}/${streak.lastPlayDate!.year}',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 32),
          const Text('Metas de Racha',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...milestones.map((m) => _milestoneRow(
                days: m,
                achieved: streak.longestStreak >= m,
                current: streak.currentStreak >= m,
              )),
        ],
      ),
    );
  }

  Widget _milestoneRow({required int days, required bool achieved, required bool current}) {
    final icons = {
      3: '🥉',
      7: '🥈',
      14: '🌙',
      30: '🔥',
      60: '💪',
      100: '👑',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(icons[days] ?? '🎯', style: const TextStyle(fontSize: 28)),
        title: Text('$days días seguidos'),
        trailing: achieved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : (current
                ? const Text('¡En progreso!', style: TextStyle(fontSize: 12, color: Colors.orange))
                : Text('$days', style: TextStyle(color: Colors.grey.shade400))),
      ),
    );
  }
}
