import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';

class HistoryCard extends StatelessWidget {
  final Map<String, dynamic> game;

  const HistoryCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mode = game['mode'] ?? 'local';
    final timestamp = game['createdAt'];

    String dateText = '';

    if (timestamp != null) {
      dateText = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }

    Color accent;
    IconData icon;
    String modeLabel;

    switch (mode) {
      case 'online':
        accent = const Color(0xFF4A90E2);
        icon = Icons.wifi;
        modeLabel = 'En línea';
        break;
      case 'random':
        accent = const Color(0xFF4CAF50);
        icon = Icons.shuffle;
        modeLabel = 'Aleatoria';
        break;
      default:
        accent = AppColors.pink;
        icon = Icons.favorite;
        modeLabel = 'Local';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        // Handle tap event
        context.push('/historyDetail', extra: game);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ac.surface,
          borderRadius: BorderRadius.circular(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${game['player1']} 💕 ${game['player2']}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    modeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "${game['questionsAnswered']} preguntas respondidas",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: ac.textSecondary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Fecha: $dateText",
              style: TextStyle(color: ac.textMuted),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (game['categories'] as List<dynamic>? ?? const [])
                  .map(
                    (cat) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ac.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cat.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: ac.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
