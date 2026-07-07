import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovequiz_app/services/social_service.dart';
import 'package:lovequiz_app/models/social_model.dart';
import 'package:intl/intl.dart';

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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Amigos'),
            Tab(icon: Icon(Icons.person_add), text: 'Invitaciones'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Estadísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendsTab(),
          _InvitationsTab(),
          _StatsTab(),
        ],
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar amigos por alias...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (query) => _searchAndAdd(context, query),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: SocialService.friendsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Busca y agrega amigos', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron usuarios')),
        );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitación enviada a ${results[i]['alias']}')),
                    );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(friend.photoUrl != null ? Icons.person : Icons.person),
        ),
        title: Text(friend.alias),
        subtitle: friend.since != null
            ? Text('Amigos desde ${DateFormat('dd/MM/yyyy').format(friend.since!)}')
            : null,
        trailing: const Icon(Icons.favorite, color: Colors.pink, size: 20),
      ),
    );
  }
}

class _InvitationsTab extends StatelessWidget {
  const _InvitationsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: SocialService.invitationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No tienes invitaciones', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add)),
                title: Text('${inv.fromAlias} quiere ser tu amigo'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(inv.createdAt)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => SocialService.acceptInvitation(inv.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => SocialService.rejectInvitation(inv.id),
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

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await SocialService.getGameStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final stats = _stats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estadísticas del Juego',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => context.push('/history'),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Historial'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          _statCard(Icons.sports_esports, 'Partidas', '${stats.totalGames}', Colors.pink),
          _statCard(Icons.quiz, 'Preguntas', '${stats.totalQuestions}', Colors.blue),
          _statCard(Icons.timer, 'Minutos', '${stats.totalMinutes}', Colors.orange),
          _statCard(Icons.people, 'Amigos', '${stats.totalFriends}', Colors.green),
          const SizedBox(height: 24),
          const Text('Rachas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _statCard(Icons.local_fire_department, 'Racha Actual',
              '${stats.currentStreak} días', Colors.deepOrange),
          _statCard(Icons.emoji_events, 'Mejor Racha',
              '${stats.longestStreak} días', Colors.amber),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
