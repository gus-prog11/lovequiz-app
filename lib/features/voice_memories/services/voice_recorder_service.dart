import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _filePath;

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

  Future<bool> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _filePath = '${dir.path}/voice_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );
    return true;
  }

  Future<String?> stopRecording() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    if (path != null) _filePath = path;
    return _filePath;
  }

  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
    _filePath = null;
  }

  Future<void> play() async {
    if (_filePath == null || !File(_filePath!).existsSync()) return;
    await _player.setFilePath(_filePath!);
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
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
  }

  Future<void> reRecord() async {
    await deleteFile();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _recorder.dispose();
  }
}
