import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _filePath;
  String? _loadedPath;
  Timer? _maxDurationTimer;

  String? get filePath => _filePath;
  bool get hasFile => _filePath != null && File(_filePath!).existsSync();
  bool get isPlaying => _player.playing;

  Future<bool> get isRecording => _recorder.isRecording();

  Stream<Duration> get onPositionChanged => _player.positionStream;
  Stream<PlayerState> get onPlayerStateChanged => _player.playerStateStream;
  Duration? get duration => _player.duration;

  Future<bool> requestPermission() async {
    final hasPermission = await _recorder.hasPermission();
    return hasPermission;
  }

  /// Indica si el acceso al micrófono fue denegado permanentemente.
  /// Permite ofrecer al usuario abrir la configuración del dispositivo.
  Future<bool> isPermissionPermanentlyDenied() async {
    return await Permission.microphone.status.isPermanentlyDenied;
  }

  /// Duración máxima de grabación en segundos.
  static const int maxDurationSeconds = 120;

  Future<bool> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _filePath = '${dir.path}/voice_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );

    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(
      const Duration(seconds: maxDurationSeconds),
      () async {
        if (await _recorder.isRecording()) {
          await stopRecording();
        }
      },
    );
    return true;
  }

  Future<String?> stopRecording() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    if (path != null) _filePath = path;
    return _filePath;
  }

  Future<void> cancelRecording() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
    _filePath = null;
  }

  Future<void> play() async {
    if (_filePath == null || !File(_filePath!).existsSync()) return;
    try {
      // `setFilePath` reinicia la reproducción desde 0. Si el archivo ya está
      // cargado (pausa previa), NO se recarga: así `play()` reanuda desde donde
      // quedó en vez de volver al inicio (M13).
      if (_loadedPath != _filePath) {
        await _player.setFilePath(_filePath!);
        _loadedPath = _filePath;
      }
      await _player.play();
    } catch (e) {
      debugPrint('[VoiceRecorder] play error: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('[VoiceRecorder] pause error: $e');
    }
  }

  /// Carga el archivo recién grabado en el player y devuelve su duración.
  ///
  /// Tras detener la grabación el player todavía no conoce el archivo (la
  /// duración solo está disponible después de `setFilePath`). Sin esto el
  /// preview quedaba en "00:00 / 00:00" y el progreso en 0 hasta reproducir
  /// por primera vez (M12).
  Future<Duration?> fileDuration() async {
    if (_filePath == null || !File(_filePath!).existsSync()) return null;
    try {
      if (_loadedPath != _filePath) {
        await _player.setFilePath(_filePath!);
        _loadedPath = _filePath;
      }
      return _player.duration;
    } catch (e) {
      debugPrint('[VoiceRecorder] fileDuration error: $e');
      return null;
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[VoiceRecorder] stopPlayback error: $e');
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> deleteFile() async {
    await stopPlayback();
    if (_filePath != null) {
      final file = File(_filePath!);
      if (file.existsSync()) await file.delete();
    }
    _filePath = null;
    _loadedPath = null;
  }

  Future<void> reRecord() async {
    await deleteFile();
  }

  /// Libera el player y el recorder.
  ///
  /// Antes de destruir el recorder se cancela una grabación ACTIVA (si el
  /// usuario sale a mitad de grabación, `AudioRecorder.dispose()` sin
  /// `cancel()` dejaba un `.m4a` parcial/corrupto en disco y cerraba la sesión
  /// de micrófono abruptamente — R7).
  ///
  /// NOTA: No se borra el archivo aquí. El生命周期 del archivo lo gestiona
  /// el widget padre (`VoiceQuestionCard`): si la subida a Cloudinary está en
  /// curso, el archivo se necesita y se borrará al completar. Si el widget se
  /// descarta sin subida, él se encarga de limpiar.
  Future<void> dispose() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    await _player.dispose();
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
    await _recorder.dispose();
  }
}
