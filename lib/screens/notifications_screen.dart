import 'package:LoveQuiz/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/fade_slide_in.dart';

// Color de marca de la app.
const Color _pink = Color(0xFFFF2E93);

// Pantalla de notificaciones con lista en tiempo real desde Firestore.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: uid == null
                    ? Center(
                        child: Text(
                          'Inicia sesión para ver notificaciones',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      )
                    : _buildNotificationsList(uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Barra superior con botón de retroceso y título.
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.of(context).textPrimary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Notificaciones',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _markAllAsRead(),
            icon: const Icon(Icons.done_all, color: _pink, size: 22),
            tooltip: 'Marcar todo como leído',
          ),
        ],
      ),
    );
  }

  // Lista de notificaciones desde Firestore en tiempo real.
  Widget _buildNotificationsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isRead = data['read'] == true;
            return FadeSlideIn(
              delay: Duration(milliseconds: index * 50),
              child: _NotificationCard(
                title: data['title'] ?? '',
                body: data['body'] ?? '',
                type: data['type'] ?? 'info',
                timestamp: data['timestamp'],
                isRead: isRead,
                onTap: () => _markAsRead(docs[index].reference),
              ),
            );
          },
        );
      },
    );
  }

  // Estado vacío cuando no hay notificaciones.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: _pink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aquí aparecerán las actualizaciones\nde tu pareja y tus logros',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Marca una notificación como leída.
  Future<void> _markAsRead(DocumentReference ref) async {
    await ref.update({'read': true});
  }

  // Marca todas las notificaciones como leídas.
  Future<void> _markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

// Tarjeta individual de notificación.
class _NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final dynamic timestamp;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? ac.surfaceAlt.withValues(alpha: 0.7)
              : ac.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? ac.border
                : _pink.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: ac.textPrimary.withValues(
                              alpha: isRead ? 0.6 : 1.0,
                            ),
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: ac.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icono circular según el tipo de notificación.
  Widget _buildIcon() {
    final (icon, color) = switch (type) {
      'game_result' => (Icons.videogame_asset_rounded, Colors.amber),
      'achievement' => (Icons.emoji_events_rounded, Colors.orange),
      'partner_answer' => (Icons.favorite_rounded, _pink),
      'streak' => (Icons.local_fire_department_rounded, Colors.deepOrange),
      'reminder' => (Icons.alarm_rounded, Colors.cyan),
      'system' => (Icons.info_outline_rounded, Colors.blueGrey),
      _ => (Icons.notifications_rounded, _pink),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // Formatea el timestamp a texto legible.
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

// Utilidad estática para crear notificaciones desde otros servicios.
class NotificationHelper {
  static Future<void> send({
    required String uid,
    required String title,
    required String body,
    required String type,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // Retorna el conteo de notificaciones no leídas.
  static Stream<int> unreadCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
