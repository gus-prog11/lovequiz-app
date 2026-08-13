import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> game;

  const HistoryDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mode = game['mode'] ?? 'local';
    final timestamp = game['createdAt'];

    String dateText = 'Sin fecha';

    if (timestamp != null) {
      dateText = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
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

    final categories = (game['categories'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        title: Text(
          'Detalle de Partida',
          style: TextStyle(color: ac.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Encabezado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "${game['player1']} 💕 ${game['player2']}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      modeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Estadísticas
            _InfoCard(
              title: "Preguntas respondidas",
              value: "${game['questionsAnswered'] ?? 0}",
              icon: Icons.question_answer,
            ),

            const SizedBox(height: 12),

            _InfoCard(
              title: "Fecha",
              value: dateText,
              icon: Icons.calendar_month,
            ),

            const SizedBox(height: 24),

            // Categorías
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Categorías",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ac.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 16,
                        color: AppColors.pink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: TextStyle(
                          color: ac.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Resumen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 28,
                      color: AppColors.pink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Resumen',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ac.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "${game['player1']} y ${game['player2']} respondieron "
                    "${game['questionsAnswered'] ?? 0} preguntas juntos "
                    "en una partida $modeLabel.",
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.4, color: ac.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  "Volver",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(18),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ac.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.pink, size: 22),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ac.textPrimary,
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
