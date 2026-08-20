import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/app_colors.dart';
import '../../../utils/app_toast.dart';
import '../services/voice_recorder_service.dart';

const Color _pink = AppColors.pink;
const int _maxSeconds = 20;

enum _RecorderState { idle, recording, recorded, playing }

class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String audioPath) onCompleted;

  const VoiceRecorderWidget({super.key, required this.onCompleted});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final VoiceRecorderService _service = VoiceRecorderService();
  _RecorderState _state = _RecorderState.idle;
  int _elapsedSeconds = 0;
  bool _starting = false;
  bool _stopping = false;
  Timer? _recordingTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  Duration _position = Duration.zero;
  Duration? _audioDuration;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _pulseCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _setState(_RecorderState newState) {
    if (mounted) setState(() => _state = newState);
  }

  Future<void> _requestPermissionAndRecord() async {
    // Bloquea toques repetidos mientras se pide el permiso o se inicia la
    // grabación, para no crear grabaciones duplicadas.
    if (_starting || _state == _RecorderState.recording) return;
    _starting = true;
    try {
      final granted = await _service.requestPermission();
      if (!granted) {
        if (await _service.isPermissionPermanentlyDenied()) {
          if (!mounted) return;
          _showPermissionDialog();
        } else if (mounted) {
          AppToast.showWarning(context, 'Para grabar, permite el acceso al micrófono.');
        }
        return;
      }
      await _service.startRecording();
      _elapsedSeconds = 0;
      _setState(_RecorderState.recording);
      _pulseCtrl.repeat(reverse: true);
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _maxSeconds) {
          _stopRecording();
        }
        if (mounted) setState(() {});
      });
    } catch (_) {
      // Si el dispositivo impide iniciar la grabación, no dejar el widget en
      // un estado intermedio.
      if (mounted) _setState(_RecorderState.idle);
    } finally {
      _starting = false;
    }
  }

  /// Permiso denegado permanentemente: ofrece abrir la configuración del
  /// dispositivo para activar el micrófono manualmente.
  void _showPermissionDialog() {
    final ac = AppColors.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ac.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Permiso de micrófono',
          style: TextStyle(color: ac.textPrimary),
        ),
        content: Text(
          'Para grabar mensajes de voz, activa el acceso al micrófono '
          'en la configuración del dispositivo.',
          style: TextStyle(color: ac.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Ahora no',
              style: TextStyle(color: ac.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecording() async {
    // Guard de reentrada: el timer de 20s y un tap simultáneo en "Detener"
    // podían ejecutar esto dos veces y DUPLICAR las suscripciones al player
    // (un segundo `_setupPlayerListeners` re-suscribía la posición y el estado,
    // con progreso y transiciones erráticas) (M11).
    if (_stopping) return;
    _stopping = true;
    try {
      _recordingTimer?.cancel();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      await _service.stopRecording();
      if (_service.hasFile) {
        // Se rellena la duración YA: sin esto el preview quedaba en
        // "00:00 / 00:00" y el progreso en 0 hasta que se pulsara play (M12).
        _audioDuration = await _service.fileDuration();
        _setupPlayerListeners();
        _setState(_RecorderState.recorded);
      } else {
        _setState(_RecorderState.idle);
      }
    } catch (e) {
      debugPrint('[VoiceRecorder] stopRecording error: $e');
      if (mounted) _setState(_RecorderState.idle);
    } finally {
      _stopping = false;
    }
  }

  void _setupPlayerListeners() {
    // Cancelar las previas antes de crear las nuevas: tras la reentrada fix de
    // `_stopRecording` ya no debería pasar, pero es defensa barata contra
    // suscripciones acumuladas si el widget cambia de estado (M11).
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub = _service.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _playerStateSub = _service.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _setState(_RecorderState.recorded);
        _position = Duration.zero;
      } else if (state.playing) {
        _setState(_RecorderState.playing);
      } else if (_state == _RecorderState.playing) {
        _setState(_RecorderState.recorded);
      }
    });
  }

  Future<void> _play() async {
    try {
      _audioDuration = _service.duration;
      await _service.play();
    } catch (e) {
      debugPrint('[VoiceRecorder] play failed: $e');
      if (mounted) {
        AppToast.showError(context, 'No se pudo reproducir el audio.');
        _setState(_RecorderState.recorded);
      }
    }
  }

  Future<void> _pause() async {
    await _service.pause();
  }

  Future<void> _delete() async {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _position = Duration.zero;
    _audioDuration = null;
    await _service.deleteFile();
    _setState(_RecorderState.idle);
  }

  Future<void> _retry() async {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _position = Duration.zero;
    _audioDuration = null;
    await _service.reRecord();
    await _requestPermissionAndRecord();
  }

  void _confirm() {
    if (_service.hasFile) {
      widget.onCompleted(_service.filePath!);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (_state == _RecorderState.recording) {
      return _elapsedSeconds / _maxSeconds;
    }
    if (_state == _RecorderState.playing || _state == _RecorderState.recorded) {
      if (_audioDuration != null && _audioDuration!.inMilliseconds > 0) {
        return _position.inMilliseconds / _audioDuration!.inMilliseconds;
      }
    }
    return 0;
  }

  String get _timeDisplay {
    if (_state == _RecorderState.recording) {
      return _formatTime(_elapsedSeconds);
    }
    if (_state == _RecorderState.playing || _state == _RecorderState.recorded) {
      final total = _audioDuration ?? Duration.zero;
      return '${_formatTime(_position.inSeconds)} / ${_formatTime(total.inSeconds)}';
    }
    return '00:00';
  }

  /// Escala los tamaños fijos según el ancho del dispositivo para que los
  /// botones se vean igual de bien en pantallas chicas y grandes. Se acota
  /// para que en extremos no se vea deformado.
  double _scale(double value) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    return value * (shortest / 360).clamp(0.85, 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);

    return Container(
      padding: EdgeInsets.all(_scale(20)),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pink.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTimer(),
          const SizedBox(height: 12),
          _buildProgressBar(),
          const SizedBox(height: 20),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.mic,
          color: _state == _RecorderState.recording
              ? _pink
              : _pink.withValues(alpha: 0.6),
          size: _scale(20),
        ),
        const SizedBox(width: 8),
        Text(
          _state == _RecorderState.idle
              ? 'Grabar mensaje de voz'
              : _state == _RecorderState.recording
                  ? 'Grabando...'
                  : 'Audio grabado',
          style: TextStyle(
            color: _pink.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (_state == _RecorderState.recorded)
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            onPressed: _confirm,
          ),
        if (_state == _RecorderState.recording)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildTimer() {
    final ac = AppColors.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: FittedBox(
        key: ValueKey(_state),
        fit: BoxFit.scaleDown,
        child: Text(
          _timeDisplay,
          style: TextStyle(
            color: _state == _RecorderState.recording ||
                    _state == _RecorderState.idle
                ? ac.textPrimary
                : ac.textPrimary.withValues(alpha: 0.8),
            fontSize: _scale(36),
            fontWeight: FontWeight.w300,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final ac = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        backgroundColor: ac.border,
        valueColor: AlwaysStoppedAnimation<Color>(
          _state == _RecorderState.recording
              ? _pink
              : _pink.withValues(alpha: 0.8),
        ),
        minHeight: 6,
      ),
    );
  }

  Widget _buildControls() {
    switch (_state) {
      case _RecorderState.idle:
        return _buildIdleControls();
      case _RecorderState.recording:
        return _buildRecordingControls();
      case _RecorderState.recorded:
        return _buildRecordedControls();
      case _RecorderState.playing:
        return _buildPlayingControls();
    }
  }

  Widget _buildIdleControls() {
    final micSize = _scale(64);
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return GestureDetector(
          onTap: _requestPermissionAndRecord,
          child: Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: micSize,
              height: micSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_pink, AppColors.pinkGradientEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.mic, color: Colors.white, size: _scale(28)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingControls() {
    final size = _scale(64);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: _pink.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: Icon(Icons.stop, color: Colors.white, size: _scale(28)),
            onPressed: _stopRecording,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordedControls() {
    final size = _scale(64);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(Icons.delete_outline, Colors.redAccent, _delete),
        const SizedBox(width: 24),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_pink, AppColors.pink],
            ),
            boxShadow: [
              BoxShadow(
                color: _pink.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.play_arrow, color: Colors.white, size: _scale(28)),
            onPressed: _play,
          ),
        ),
        const SizedBox(width: 24),
        _buildCircleButton(Icons.refresh, Colors.white70, _retry),
      ],
    );
  }

  Widget _buildPlayingControls() {
    final size = _scale(64);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(Icons.delete_outline, Colors.redAccent, _delete),
        const SizedBox(width: 24),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_pink, AppColors.pink],
            ),
            boxShadow: [
              BoxShadow(
                color: _pink.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.pause, color: Colors.white, size: _scale(28)),
            onPressed: _pause,
          ),
        ),
        const SizedBox(width: 24),
        _buildCircleButton(Icons.refresh, Colors.white70, _retry),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onTap) {
    final ac = AppColors.of(context);
    final size = _scale(48);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ac.surfaceAlt.withValues(alpha: 0.6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: _scale(22)),
        onPressed: onTap,
      ),
    );
  }
}
