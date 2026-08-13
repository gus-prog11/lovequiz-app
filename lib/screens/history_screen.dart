import 'package:LoveQuiz/cards/history_card.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../widgets/fade_slide_in.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Fuerza que el StreamBuilder se reconstruya y vuelva a suscribirse al stream.
  int _retryCount = 0;

  void _retry() {
    setState(() => _retryCount++);
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);

    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: ac.background,
        title: Text(
          'Historial',
          style: TextStyle(color: ac.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder(
        key: ValueKey(_retryCount),
        stream: FirestoreService.getUserHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pink),
            );
          }
          if (snapshot.hasError) {
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
                    'No se pudo cargar el historial',
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Revisa tu conexión e inténtalo de nuevo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ac.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Reintentar"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pink,
                      side: BorderSide(color: AppColors.pink.withValues(alpha: .5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
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
                      Icons.history,
                      size: 40,
                      color: AppColors.pink.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay partidas aún',
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tus partidas aparecerán aquí',
                    style: TextStyle(color: ac.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return FadeSlideIn(
                delay: Duration(milliseconds: index * 50),
                child: HistoryCard(game: data),
              );
            },
          );
        },
      ),
    );
  }
}
