import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/models/social_model.dart';
import 'package:LoveQuiz/services/social_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';
import 'package:LoveQuiz/utils/app_toast.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'Social',
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
            Tab(icon: Icon(Icons.people), text: 'Amigos'),
            Tab(icon: Icon(Icons.person_add), text: 'Invitaciones'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Estadísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_FriendsTab(), _InvitationsTab(), _StatsTab()],
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            style: TextStyle(color: ac.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar amigos por alias...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: ac.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ac.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.pink, width: 2),
              ),
            ),
            onSubmitted: (query) => _searchAndAdd(context, query),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: SocialService.friendsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.pink),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.pink.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_outline,
                          size: 40,
                          color: AppColors.pink.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Busca y agrega amigos',
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final friend = FriendModel.fromMap(data);
                  return _FriendTile(friend: friend);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _searchAndAdd(BuildContext context, String query) async {
    final results = await SocialService.searchUsers(query);
    if (!context.mounted || results.isEmpty) {
      if (context.mounted) {
        AppToast.showInfo(context, 'No se encontraron usuarios');
      }
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Amigo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (_, i) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(results[i]['alias'] ?? ''),
              trailing: FilledButton.tonalIcon(
                onPressed: () async {
                  await SocialService.sendFriendRequest(results[i]['uid']);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    AppToast.showSuccess(context, 'Invitación enviada a ${results[i]['alias']}');
                  }
                },
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Agregar'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendModel friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ac.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, color: AppColors.pink),
        ),
        title: Text(
          friend.alias,
          style: TextStyle(color: ac.textPrimary),
        ),
        subtitle: friend.since != null
            ? Text(
                'Amigos desde ${DateFormat('dd/MM/yyyy').format(friend.since!)}',
                style: TextStyle(color: ac.textMuted),
              )
            : null,
        trailing: const Icon(Icons.favorite, color: AppColors.pink, size: 20),
      ),
    );
  }
}

class _InvitationsTab extends StatelessWidget {
  const _InvitationsTab();

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return StreamBuilder<QuerySnapshot>(
      stream: SocialService.invitationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.pink),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.pink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    size: 40,
                    color: AppColors.pink.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes invitaciones',
                  style: TextStyle(color: ac.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final inv = InvitationModel.fromMap(data);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ac.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_add, color: AppColors.pink),
                ),
                title: Text(
                  '${inv.fromAlias} quiere ser tu amigo',
                  style: TextStyle(color: ac.textPrimary),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(inv.createdAt),
                  style: TextStyle(color: ac.textMuted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      onPressed: () async {
                        try {
                          await SocialService.acceptInvitation(inv.id);
                        } catch (e) {
                          debugPrint('[Social] acceptInvitation error: $e');
                          if (!context.mounted) return;
                          AppToast.showError(
                            context,
                            'No se pudo aceptar la solicitud. Revisa tu conexión e inténtalo de nuevo.',
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () =>
                          SocialService.rejectInvitation(inv.id),
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

class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  GameStats? _stats;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SocialService.getGameStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[StatsTab] _loadStats error: $e');
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      );
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.pink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar las estadísticas',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Revisa tu conexión e inténtalo de nuevo',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => setState(() { _error = false; _loading = true; _loadStats(); }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Reintentar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.pink,
                side: BorderSide(color: AppColors.pink.withValues(alpha: .5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    final ac = AppColors.of(context);
    final stats = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estadísticas del Juego',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ac.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Historial'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statCard(
            Icons.sports_esports,
            'Partidas',
            '${stats.totalGames}',
          ),
          _statCard(
            Icons.quiz,
            'Preguntas',
            '${stats.totalQuestions}',
          ),
          _statCard(
            Icons.timer,
            'Minutos',
            '${stats.totalMinutes}',
          ),
          _statCard(
            Icons.people,
            'Amigos',
            '${stats.totalFriends}',
          ),
          const SizedBox(height: 24),
          Text(
            'Rachas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _statCard(
            Icons.local_fire_department,
            'Racha Actual',
            '${stats.currentStreak} días',
          ),
          _statCard(
            Icons.emoji_events,
            'Mejor Racha',
            '${stats.longestStreak} días',
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.pink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.pink, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(color: ac.textPrimary),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.pink,
          ),
        ),
      ),
    );
  }
}
