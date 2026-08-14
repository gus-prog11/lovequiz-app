import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../config/app_colors.dart';

const Color _pink = AppColors.pink;

/// Fila de reproducción de un mensaje de voz en la revelación.
///
/// Soporta audio remoto (`url`, partidas online) y archivo local
/// (`localPath`, partidas locales). Solo suena un mensaje a la vez: al
/// reproducir uno, se detiene cualquier otro (patrón compartido con
/// `VoiceMemoryCard`).
class VoiceRevealPlayer extends StatefulWidget {
  final String label;
  final String? url;
  final String? localPath;

  const VoiceRevealPlayer({
    super.key,
    required this.label,
    this.url,
    this.localPath,
  }) : assert(url != null || localPath != null,
            'Se requiere url o localPath');

  @override
  State<VoiceRevealPlayer> createState() => _VoiceRevealPlayerState();
}

class _VoiceRevealPlayerState extends State<VoiceRevealPlayer> {
  AudioPlayer? _activePlayer;
  Duration? _position;
  Duration? _duration;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  static AudioPlayer? _anyActivePlayer;
  static void Function()? _anyStop;

  /// `false` hasta que un `play()` tenga éxito. `playerStateStream` emite el
  /// estado inicial `idle`/`playing=false` justo al suscribirse (y también
  /// queda `idle` al detener este reproductor porque otro empieza a sonar),
  /// así que sin esta guarda se mostraría un SnackBar de error falso.
  bool _startedPlayback = false;

  bool get _isPlaying =>
      _activePlayer?.playing == true && _anyActivePlayer == _activePlayer;

  @override
  void dispose() {
    if (_activePlayer != null && _anyActivePlayer == _activePlayer) {
      _anyActivePlayer = null;
      _anyStop = null;
    }
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _activePlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_activePlayer == null) {
      _activePlayer = AudioPlayer();
      _durationSub = _activePlayer!.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _positionSub = _activePlayer!.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _stateSub = _activePlayer!.playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed) {
          setState(() => _position = _duration);
        } else if (_startedPlayback &&
            state.processingState == ProcessingState.idle &&
            !state.playing) {
          _handlePlaybackError();
        }
      });
    }

    if (_isPlaying) {
      await _activePlayer!.pause();
      return;
    }

    if (_anyActivePlayer != null && _anyActivePlayer != _activePlayer) {
      // Se marca "no iniciado" ANTES de detener: el `stop()` del otro
      // reproductor emite un estado `idle` que, sin esta guarda, se
      // interpretaría como un error de reproducción.
      _anyStop?.call();
      await _anyActivePlayer!.stop();
    }

    try {
      final source = widget.localPath != null
          ? AudioSource.file(widget.localPath!)
          : AudioSource.uri(Uri.parse(widget.url!));
      await _activePlayer!.setAudioSource(source);
      await _activePlayer!.play();
    } catch (_) {
      _handlePlaybackError();
      return;
    }

    _startedPlayback = true;
    _anyActivePlayer = _activePlayer;
    _anyStop = () {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _startedPlayback = false;
        });
      }
    };
    if (mounted) setState(() {});
  }

  void _handlePlaybackError() {
    _startedPlayback = false;
    if (mounted) {
      setState(() {
        _position = null;
        _duration = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.localPath != null
                ? 'Este audio ya no está disponible.'
                : 'No se pudo reproducir este audio.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final playing = _isPlaying;
    final display = playing
        ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
        : _formatDuration(_duration);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ac.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _pink.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: _pink,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              display,
              style: TextStyle(color: ac.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
