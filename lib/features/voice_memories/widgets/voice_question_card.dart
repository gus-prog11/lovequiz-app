import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../services/voice_storage_service.dart';
import '../widgets/voice_recorder_widget.dart';

const Color _pink = AppColors.pink;

enum _VoiceQuestionState { input, sent, uploading, error, uploaded, waiting }

class VoiceQuestionCard extends StatefulWidget {
  final String questionText;
  final String playerName;
  final String coupleId;
  final bool isLastQuestion;
  final VoidCallback onContinue;

  /// Returns true when BOTH players have already uploaded their audio.
  final Future<bool> Function(UploadedVoice uploaded)? onUploaded;

  /// Emits true when the partner finishes uploading (online mode).
  final Stream<bool>? partnerUploadedStream;

  /// Modo local: el audio se graba para la experiencia de la pregunta pero
  /// no se sube a Cloudinary ni se persiste en Firestore. Los recuerdos de
  /// voz solo se conservan en partidas online con pareja.
  final bool localMode;

  const VoiceQuestionCard({
    super.key,
    required this.questionText,
    required this.playerName,
    required this.coupleId,
    required this.onContinue,
    this.onUploaded,
    this.partnerUploadedStream,
    this.isLastQuestion = false,
    this.localMode = false,
  });

  @override
  State<VoiceQuestionCard> createState() => _VoiceQuestionCardState();
}

class _VoiceQuestionCardState extends State<VoiceQuestionCard> {
  final VoiceStorageService _storageService = VoiceStorageService();
  _VoiceQuestionState _state = _VoiceQuestionState.input;
  String? _audioPath;
  String? _uploadError;
  bool _sending = false;
  StreamSubscription<bool>? _partnerSub;

  /// Audio ya subido a Cloudinary. Se conserva entre reintentos para no
  /// duplicar el asset si solo falla la escritura en Firestore.
  UploadedVoice? _uploadedVoice;

  @override
  void initState() {
    super.initState();
    _partnerSub = widget.partnerUploadedStream?.listen((done) {
      if (done && mounted) {
        setState(() => _state = _VoiceQuestionState.uploaded);
      }
    });
  }

  @override
  void dispose() {
    _partnerSub?.cancel();
    super.dispose();
  }

  void _onAudioCompleted(String path) {
    _audioPath = path;
    if (mounted) setState(() => _state = _VoiceQuestionState.sent);
  }

  Future<void> _confirmSend() async {
    // Bloquea el botón mientras un envío está en curso para evitar que un
    // doble tap duplique la subida o la escritura en Firestore.
    if (_audioPath == null || _sending) return;
    _sending = true;
    try {
      // Modo local: no se crea ningún recuerdo persistente. Se avisa y se
      // avanza al siguiente turno/pregunta sin subir nada.
      if (widget.localMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'En modo local los mensajes de voz no se guardan. '
              'Los recuerdos de voz solo se conservan en partidas con tu pareja.',
            ),
          ),
        );
        widget.onContinue();
        return;
      }

      setState(() {
        _state = _VoiceQuestionState.uploading;
        _uploadError = null;
      });

      try {
        // Si el audio ya se subió (falló solo la escritura en Firestore),
        // se reutiliza para no generar assets duplicados en Cloudinary.
        _uploadedVoice ??= await _storageService.uploadVoice(
          localPath: _audioPath!,
          coupleId: widget.coupleId,
        );

        if (!mounted) return;

        var bothUploaded = true;
        if (widget.onUploaded != null) {
          bothUploaded = await widget.onUploaded!(_uploadedVoice!);
        }
        if (!mounted) return;
        setState(() {
          _state = bothUploaded
              ? _VoiceQuestionState.uploaded
              : _VoiceQuestionState.waiting;
        });
      } catch (e) {
        if (!mounted) return;
        debugPrint('[VoiceQuestionCard] Upload failed: $e');
        setState(() {
          _state = _VoiceQuestionState.error;
          _uploadError = _uploadedVoice == null
              ? (e is VoiceUploadException
                    ? e.message
                    : 'No se pudo subir el audio. Verifica tu conexión e inténtalo nuevamente.')
              : 'Tu audio se subió, pero no se pudo guardar. Intenta nuevamente.';
        });
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> _retry() async {
    await _confirmSend();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    final ac = AppColors.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: _pink, size: 16),
            const SizedBox(width: 6),
            Text(
              'Momento de Voz',
              style: TextStyle(
                color: _pink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.questionText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: ac.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Centra el contenido cuando hay espacio y lo hace desplazable cuando la
  /// pantalla es pequeña, para que nunca se desborde (patrón de apps
  /// profesionales).
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: switch (_state) {
                _VoiceQuestionState.input => _buildInputState(),
                _VoiceQuestionState.sent => _buildSentState(),
                _VoiceQuestionState.uploading => _buildUploadingState(),
                _VoiceQuestionState.error => _buildErrorState(),
                _VoiceQuestionState.uploaded => _buildUploadedState(),
                _VoiceQuestionState.waiting => _buildWaitingState(),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputState() {
    final ac = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          'Graba un mensaje de voz para tu pareja',
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Máximo 20 segundos',
          style: TextStyle(
            color: ac.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        VoiceRecorderWidget(onCompleted: _onAudioCompleted),
      ],
    );
  }

  Widget _buildSentState() {
    final ac = AppColors.of(context);
    return Column(
      key: const ValueKey('sent'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Respuesta lista',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu mensaje de voz está listo para enviar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        _buildNextButton('Enviar', _confirmSend),
      ],
    );
  }

  Widget _buildUploadingState() {
    final ac = AppColors.of(context);
    return Column(
      key: const ValueKey('uploading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(strokeWidth: 3, color: _pink),
        ),
        const SizedBox(height: 20),
        Text(
          'Subiendo audio...',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto puede tomar unos segundos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final ac = AppColors.of(context);
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(Icons.error_outline, color: Colors.red, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          'Error al subir',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _uploadError ?? 'Ocurrió un error inesperado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ac.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildNextButton('Reintentar', _retry),
      ],
    );
  }

  Widget _buildUploadedState() {
    final ac = AppColors.of(context);
    return Column(
      key: const ValueKey('uploaded'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.cloud_done_outlined,
            color: Colors.green,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Audio enviado correctamente',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ambos subieron su mensaje de voz.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        _buildNextButton(
          widget.isLastQuestion ? 'Finalizar' : 'Siguiente',
          widget.onContinue,
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    final ac = AppColors.of(context);
    return Column(
      key: const ValueKey('waiting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(strokeWidth: 3, color: _pink),
        ),
        const SizedBox(height: 20),
        Text(
          'Esperando a que ${widget.playerName} suba su audio...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ambos deben grabar su mensaje para continuar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [_pink, AppColors.pinkGradientEnd],
          ),
          boxShadow: [
            BoxShadow(color: _pink.withValues(alpha: 0.35), blurRadius: 20),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.arrow_forward),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
