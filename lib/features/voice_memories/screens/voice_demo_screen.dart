import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../widgets/voice_recorder_widget.dart';

class VoiceDemoScreen extends StatelessWidget {
  const VoiceDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ac.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Recuerdos de Voz',
          style: TextStyle(
            color: ac.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              Icons.multitrack_audio_rounded,
              size: 72,
              color: AppColors.pink.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Prueba de grabación de voz',
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Graba, escucha y administra tu audio.',
              style: TextStyle(color: ac.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const VoiceRecorderWidget(
              onCompleted: _onVoiceCompleted,
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  static void _onVoiceCompleted(String audioPath) {
    debugPrint('Audio guardado en: $audioPath');
  }
}
