import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para crear notificaciones in-app en Firestore.
///
/// Escribe documentos en `users/{uid}/notifications` que la pantalla
/// de notificaciones lee en tiempo real.
class NotificationService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Escribe una notificación en la subcolección del usuario.
  static Future<void> _add({
    required String type,
    required String title,
    required String body,
  }) async {
    if (_uid.isEmpty) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .add({
      'type': type,
      'title': title,
      'body': body,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Notifica al usuario que su pareja completó una partida.
  ///
  /// Se llama desde `_finishGame()` en game_play_screen.
  static Future<void> gameResult({
    required int questionsAnswered,
    required String mode,
  }) async {
    final modeLabel = mode == 'online' ? 'en línea' : 'offline';
    await _add(
      type: 'game_result',
      title: 'Partida completada',
      body:
          'Jugaron $questionsAnswered preguntas ($modeLabel). ¡Sigan así!',
    );
  }

  /// Notifica al usuario que desbloqueó un logro.
  ///
  /// Se llama desde `updateProgress()` en achievement_service cuando
  /// `unlocked` pasa de false a true.
  static Future<void> achievement({
    required String achievementId,
    required String achievementName,
  }) async {
    await _add(
      type: 'achievement',
      title: '¡Logro desbloqueado!',
      body: achievementName,
    );
  }

  /// Notifica al usuario que su pareja grabó un recuerdo de voz.
  ///
  /// Se llama desde `savePlayerAudio()` en voice_memory_repository cuando
  /// el otro jugador sube su audio.
  static Future<void> partnerAnswer({
    required String partnerName,
  }) async {
    await _add(
      type: 'partner_answer',
      title: 'Nuevo recuerdo de voz',
      body: '$partnerName grabó un recuerdo. ¡Escúchalo!',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers para determinar el partner UID a partir de la coupleId.
  // ---------------------------------------------------------------------------

  /// Returns the partner's UID given the current user and coupleId.
  static Future<String?> getPartnerUid(String coupleId) async {
    if (_uid.isEmpty) return null;
    final coupleDoc = await _db.collection('couples').doc(coupleId).get();
    if (!coupleDoc.exists) return null;
    final data = coupleDoc.data();
    if (data == null) return null;
    final user1 = data['user1Id'] as String? ?? '';
    final user2 = data['user2Id'] as String? ?? '';
    if (user1 == _uid) return user2;
    if (user2 == _uid) return user1;
    return null;
  }
}
