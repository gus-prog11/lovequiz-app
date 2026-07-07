import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> game;

  const HistoryDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final mode = game['mode'] ?? 'local';
    final timestamp = game['createdAt'];

    String dateText = 'Sin fecha';

    if (timestamp != null) {
      dateText = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    }

    Color color;
    IconData icon;

    switch (mode) {
      case 'online':
        color = Colors.blue.shade100;
        icon = Icons.wifi;
        break;

      case 'random':
        color = Colors.green.shade100;
        icon = Icons.shuffle;
        break;

      default:
        color = Colors.pink.shade100;
        icon = Icons.favorite;
    }

    final categories = (game['categories'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Partida")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Encabezado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 50, color: Colors.black87),
                  const SizedBox(height: 12),

                  Text(
                    "${game['player1']} 💕 ${game['player2']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    mode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                return Chip(
                  label: Text(category),
                  avatar: const Icon(Icons.local_offer, size: 18),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Resumen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 32),
                  const SizedBox(height: 12),

                  const Text(
                    "Resumen",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "${game['player1']} y ${game['player2']} respondieron "
                    "${game['questionsAnswered'] ?? 0} preguntas juntos "
                    "en una partida ${mode.toLowerCase()}.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.4),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
