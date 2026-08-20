import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voice_memory.dart';
import '../repositories/voice_memory_repository.dart';
import '../../../config/app_colors.dart';
import '../../../utils/app_toast.dart';

const Color _pink = AppColors.pink;

class VoiceMemoryCard extends StatefulWidget {
  final VoiceMemory memory;
  final String currentUserId;

  const VoiceMemoryCard({
    super.key,
    required this.memory,
    required this.currentUserId,
  });

  @override
  State<VoiceMemoryCard> createState() => _VoiceMemoryCardState();
}

class _VoiceMemoryCardState extends State<VoiceMemoryCard> {
  AudioPlayer? _activePlayer;
  String? _playingUrl;
  Duration? _position;
  Duration? _duration;
  bool _saving = false;

  /// `false` hasta que un `play()` tenga éxito. `playerStateStream` emite el
  /// estado inicial `idle`/`playing=false` al suscribirse, y queda `idle`
  /// al detener este reproductor porque otro mensaje empieza a sonar, así
  /// que sin esta guarda se mostraría un SnackBar de error falso.
  bool _startedPlayback = false;

  static AudioPlayer? _anyActivePlayer;
  static String? _anyPlayingUrl;
  static void Function(String?)? _anyOnChange;

  @override
  void dispose() {
    if (_activePlayer != null) {
      if (_anyPlayingUrl == _playingUrl) {
        _anyPlayingUrl = null;
        _anyActivePlayer = null;
        _anyOnChange = null;
      }
      _activePlayer!.dispose();
    }
    super.dispose();
  }

  Future<void> _togglePlay(String url) async {
    if (_playingUrl == url && _activePlayer?.playing == true) {
      await _activePlayer!.pause();
      return;
    }

    if (_anyActivePlayer != null && _anyPlayingUrl != url) {
      // Se resetea el estado del otro reproductor ANTES de detenerlo: su
      // `stop()` emite un estado `idle` que, sin la guarda `_startedPlayback`,
      // se interpretaría como un error de reproducción.
      _anyOnChange?.call(null);
      await _anyActivePlayer!.stop();
    }

    if (_activePlayer == null) {
      _activePlayer = AudioPlayer();
      _activePlayer!.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _activePlayer!.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _activePlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _anyPlayingUrl = null;
          _anyActivePlayer = null;
          _anyOnChange = null;
          if (mounted) {
            setState(() {
              _position = _duration;
              _playingUrl = null;
              _startedPlayback = false;
            });
          }
        } else if (_startedPlayback &&
            state.processingState == ProcessingState.idle &&
            !state.playing) {
          // El audio ya no está disponible (URL vacía, recurso borrado de
          // Cloudinary, etc.): se resetea y se avisa sin bloquear el botón.
          _handlePlaybackError();
        }
      });
    }

    try {
      // Si ya está cargada la fuente de este URL (pausa del mismo mensaje),
      // se reanuda desde la posición actual sin recargar ni reiniciar.
      if (_playingUrl != url) {
        await _activePlayer!.setAudioSource(
          AudioSource.uri(Uri.parse(url)),
        );
      }
      await _activePlayer!.play();
    } catch (_) {
      _handlePlaybackError();
      return;
    }

    // Si el widget se desmontó mientras el audio arrancaba, no se toca el
    // estado ni los estáticos globales (M14).
    if (!mounted) return;
    _startedPlayback = true;
    setState(() {
      _playingUrl = url;
    });
    _anyActivePlayer = _activePlayer;
    _anyPlayingUrl = url;
    _anyOnChange = (String? newUrl) {
      if (newUrl != _playingUrl && mounted) {
        setState(() {
          _playingUrl = null;
          _startedPlayback = false;
        });
      }
    };
  }

  /// Resetea el estado de reproducción tras un error y avisa al usuario de
  /// que el audio ya no está disponible.
  void _handlePlaybackError() {
    _startedPlayback = false;
    if (_anyPlayingUrl == _playingUrl) {
      _anyPlayingUrl = null;
      _anyActivePlayer = null;
      _anyOnChange = null;
    }
    if (mounted) {
      setState(() {
        _playingUrl = null;
        _position = null;
        _duration = null;
      });
    }
    if (_activePlayer != null) {
      _activePlayer!.stop();
    }
    if (mounted) {
      AppToast.showError(context, 'Este audio ya no está disponible.');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
    final months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  /// Tiempo restante calculado desde la fecha actual contra expiresAt.
  /// Se usa "se eliminará" para dejar claro que, si ambos no lo conservan,
  /// el recuerdo desaparece al expirar.
  String _remainingText(Timestamp expiresAt) {
    final remaining = expiresAt.toDate().difference(DateTime.now());
    if (remaining.isNegative) return 'Se eliminará hoy';
    if (remaining.inDays == 0) return 'Se eliminará hoy';
    if (remaining.inDays == 1) return 'Se eliminará mañana';
    return 'Se eliminará en ${remaining.inDays} días';
  }

  Widget _buildExpiryRow(VoiceMemory memory, AppColors colors) {
    return Row(
      children: [
        Icon(Icons.timer_outlined, color: colors.textMuted, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _remainingText(memory.expiresAt),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  String _playerLabel(String playerId) {
    if (playerId == widget.currentUserId) return 'Tú';
    return 'Tu pareja';
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.surface, colors.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pink.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: _pink, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    memory.displayTitle,
                    style: TextStyle(
                      color: _pink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '"${memory.question}"',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(memory.createdAt),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildAudioRow(
              label: _playerLabel(memory.player1Id),
              url: memory.player1AudioUrl,
              colors: colors,
            ),
            const SizedBox(height: 8),
            _buildAudioRow(
              label: _playerLabel(memory.player2Id),
              url: memory.player2AudioUrl,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildStatusRow(memory, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioRow({
    required String label,
    required String url,
    required AppColors colors,
  }) {
    final isPlaying = _playingUrl == url && _activePlayer?.playing == true;
    final hasPosition = _playingUrl == url && _position != null;

    String display;
    if (hasPosition && _duration != null) {
      display = '${_formatDuration(_position!)} / ${_formatDuration(_duration!)}';
    } else if (_duration != null) {
      display = _formatDuration(_duration!);
    } else {
      display = '00:00';
    }

    return GestureDetector(
      onTap: () => _togglePlay(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: _pink,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              display,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isPlayer1 =>
      widget.memory.player1Id == widget.currentUserId;

  bool get _currentUserSaved => _isPlayer1
      ? widget.memory.savedByPlayer1
      : widget.memory.savedByPlayer2;

  Future<void> _showSaveConfirmation() async {
    // Evita abrir el diálogo dos veces con toques rápidos mientras el
    // guardado anterior está en curso.
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(ctx).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Guardar este recuerdo para siempre',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Para que este recuerdo sea permanente, ambos deben guardarlo. '
          'Al guardarlo marcas tu lado y quedará en espera: si tu pareja no '
          'lo guarda antes de que expire, se eliminará.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performSave();
    }
  }

  Future<void> _performSave() async {
    setState(() => _saving = true);

    final ok = await VoiceMemoryRepository.savePermanently(
      widget.memory.gameId,
      widget.memory.id,
      widget.currentUserId,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (!ok) {
      AppToast.showError(context, 'No se pudo guardar. Intenta nuevamente.');
    }
  }

  Widget _buildStatusRow(VoiceMemory memory, AppColors colors) {
    // Permanente: solo el estado, sin contador de expiración.
    if (memory.isPermanent) {
      return Row(
        children: [
          Icon(Icons.favorite, color: _pink, size: 16),
          const SizedBox(width: 6),
          Text(
            'Guardado permanentemente',
            style: TextStyle(
              color: _pink,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Un jugador ya decidió conservarlo: se mantiene el aviso de espera y se
    // sigue mostrando el tiempo restante.
    if (_currentUserSaved) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: _pink, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tú quieres conservar este recuerdo.\nEsperando a que tu pareja también lo guarde.\nSi no lo guarda antes de que expire, se eliminará.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildExpiryRow(memory, colors),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.timer_outlined, color: colors.textMuted, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _remainingText(memory.expiresAt),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _saving ? null : _showSaveConfirmation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _saving
                    ? [colors.textMuted, colors.textMuted]
                    : [_pink, _pink.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _saving
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textPrimary,
                    ),
                  )
                : Text(
                    'Guardar para siempre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
