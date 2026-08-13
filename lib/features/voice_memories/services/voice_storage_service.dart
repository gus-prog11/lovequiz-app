import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/cloudinary_config.dart';

/// Resultado de una subida exitosa a Cloudinary.
class UploadedVoice {
  final String downloadUrl;
  final String publicId;

  const UploadedVoice({required this.downloadUrl, required this.publicId});
}

/// Error con mensaje claro para mostrar al usuario.
class VoiceUploadException implements Exception {
  final String message;
  const VoiceUploadException(this.message);

  @override
  String toString() => message;
}

class VoiceStorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Sube un audio local a Cloudinary mediante multipart/form-data.
  /// Lanza [VoiceUploadException] si no puede completar la subida.
  Future<UploadedVoice> uploadVoice({
    required String localPath,
    required String coupleId,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw const VoiceUploadException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      throw VoiceUploadException(
        'No se encontró el audio grabado. Graba nuevamente.',
      );
    }

    try {
      final ext = localPath.split('.').last.toLowerCase();
      // public_id único: el prefijo de la pareja permite localizar y eliminar
      // los audios desde Cloud Functions con la Admin API de Cloudinary.
      final publicId =
          '${_sanitize(coupleId)}_${uid}_${DateTime.now().millisecondsSinceEpoch}';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.uploadUrl),
      )
        ..fields['upload_preset'] = CloudinaryConfig.audioUploadPreset
        ..fields['folder'] = CloudinaryConfig.audioFolder
        ..fields['public_id'] = publicId
        ..fields['resource_type'] = 'video'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            localPath,
            filename: '$publicId.$ext',
            contentType: MediaType.parse(_contentTypeFor(ext)),
          ),
        );

      debugPrint(
        '[VoiceStorage] Uploading via multipart: publicId=$publicId, '
        'folder=${CloudinaryConfig.audioFolder}, ext=$ext',
      );

      // La subida no debe quedarse colgada: 30s para enviar y recibir.
      const uploadTimeout = Duration(seconds: 30);
      const timeoutMessage =
          'La subida está tardando más de lo esperado. Intenta nuevamente.';
      final streamed = await request.send().timeout(
        uploadTimeout,
        onTimeout: () => throw const VoiceUploadException(timeoutMessage),
      );
      final response = await http.Response.fromStream(streamed).timeout(
        uploadTimeout,
        onTimeout: () => throw const VoiceUploadException(timeoutMessage),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[VoiceStorage] Upload failed: '
          '${response.statusCode} ${response.body}',
        );
        throw VoiceUploadException(
          'No se pudo subir el audio (error ${response.statusCode}).',
        );
      }

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      final storedPublicId = json['public_id'] as String?;
      if (url == null || url.isEmpty || storedPublicId == null) {
        debugPrint(
          '[VoiceStorage] Unexpected Cloudinary response: ${response.body}',
        );
        throw const VoiceUploadException(
          'Respuesta inválida de Cloudinary.',
        );
      }

      debugPrint('[VoiceStorage] Upload success: $url');
      return UploadedVoice(
        downloadUrl: url,
        publicId: storedPublicId,
      );
    } on VoiceUploadException {
      rethrow;
    } catch (e) {
      debugPrint('[VoiceStorage] Exception during upload: $e');
      throw const VoiceUploadException(
        'No se pudo subir el audio. Verifica tu conexión e inténtalo nuevamente.',
      );
    }
  }

  /// Los public_id de Cloudinary solo admiten [a-zA-Z0-9_-].
  static String _sanitize(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  static String _contentTypeFor(String ext) {
    switch (ext) {
      case 'm4a':
      case 'mp4':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'amr':
        return 'audio/amr';
      default:
        return 'audio/mp4';
    }
  }
}
