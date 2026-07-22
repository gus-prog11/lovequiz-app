import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryCard extends StatelessWidget {
  final Map<String, dynamic> game;

  const HistoryCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final mode = game['mode'] ?? 'local';
    final timestamp = game['createdAt'];

    String dateText = '';

    if (timestamp != null) {
      dateText = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    }

    Color color;

    switch (mode) {
      case 'online':
        color = Colors.blue.shade100;
        break;
      case 'random':
        color = Colors.green.shade100;
        break;
      default:
        color = Colors.pink.shade100;
    }
    IconData icon;
    switch (mode) {
      case 'online':
        icon = Icons.wifi;
        break;
      case 'random':
        icon = Icons.shuffle;
        break;
      default:
        icon = Icons.favorite;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        // Handle tap event
        context.push('/historyDetail', extra: game);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${game['player1']} 💕 ${game['player2']}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "${game['questionsAnswered']} preguntas respondidas",
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(icon, color: Colors.black54),
                const SizedBox(width: 8),
                Text(mode, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Text("Fecha: $dateText", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              children: (game['categories'] as List<dynamic>)
                  .map((cat) => Chip(label: Text(cat.toString())))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
