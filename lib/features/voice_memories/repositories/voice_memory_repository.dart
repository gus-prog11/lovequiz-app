import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voice_memory.dart';

class VoiceMemoryRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to the subcollection under games/{gameId}/voice_memories.
  static CollectionReference _voiceMemoriesRef(String gameId) =>
      _db.collection('games').doc(gameId).collection('voice_memories');

  /// Generates a display title like "Recuerdo del 30 de julio".
  static String _generateDisplayTitle(DateTime date) {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return 'Recuerdo del ${date.day} de ${months[date.month]}';
  }

  /// Writes one player's audio data to the memory doc (ONLINE mode).
  ///
  /// Both players upload in parallel, so the write runs inside a transaction:
  /// each player only writes their own fields and the base fields are created
  /// only if they do not exist yet. This guarantees neither player can
  /// overwrite the other's data and both uploads end up in the same doc.
  ///
  /// Returns true when BOTH players have already uploaded their audio.
  static Future<bool> savePlayerAudio({
    required String memoryId,
    required String gameId,
    required String coupleId,
    required String question,
    String? player1Id,
    String? player1AudioUrl,
    String? player1PublicId,
    String? player2Id,
    String? player2AudioUrl,
    String? player2PublicId,
  }) async {
    final ref = _voiceMemoriesRef(gameId).doc(memoryId);

    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(ref);
        final existing = snap.exists
            ? Map<String, dynamic>.from(snap.data() as Map<String, dynamic>)
            : <String, dynamic>{};

        final now = DateTime.now();
        final patch = <String, dynamic>{
          'gameId': gameId,
          'coupleId': coupleId,
          'question': question,
          // Campos base: solo se escriben si aún no existen para que el
          // último escritor no pise los valores del primero.
          if (existing['createdAt'] == null)
            'createdAt': Timestamp.fromDate(now),
          if (existing['expiresAt'] == null)
            'expiresAt':
                Timestamp.fromDate(now.add(const Duration(days: 7))),
          if (existing['savedByPlayer1'] == null) 'savedByPlayer1': false,
          if (existing['savedByPlayer2'] == null) 'savedByPlayer2': false,
          if (existing['pending'] == null) 'pending': true,
          // Los avisos de expiración los escribe la Cloud Function; el
          // cliente solo los inicializa si aún no existen.
          if (existing['dayReminderSent'] == null) 'dayReminderSent': false,
          if (existing['finalReminderSent'] == null)
            'finalReminderSent': false,
          // Cada jugador escribe únicamente sus propios campos.
          if (player1Id != null) ...{
            'player1Id': player1Id,
            'player1AudioUrl': player1AudioUrl ?? '',
            'player1PublicId': player1PublicId ?? '',
            'answeredAtPlayer1': Timestamp.fromDate(now),
          },
          if (player2Id != null) ...{
            'player2Id': player2Id,
            'player2AudioUrl': player2AudioUrl ?? '',
            'player2PublicId': player2PublicId ?? '',
            'answeredAtPlayer2': Timestamp.fromDate(now),
          },
        };
        txn.set(ref, patch, SetOptions(merge: true));
      });

      // Después del commit, comprobar si ambos jugadores ya subieron.
      final snap = await ref.get();
      if (!snap.exists) return false;
      final d = snap.data() as Map<String, dynamic>;
      final p1Url = d['player1AudioUrl'] as String? ?? '';
      final p2Url = d['player2AudioUrl'] as String? ?? '';
      final bothUploaded = p1Url.isNotEmpty && p2Url.isNotEmpty;

      if (bothUploaded) {
        // Escritura idempotente: ambos jugadores pueden llegar aquí y
        // escribir los mismos valores sin riesgo de sobrescribir datos.
        await ref.update({
          'displayTitle': _generateDisplayTitle(DateTime.now()),
          'pending': false,
        });
      }

      debugPrint('[VoiceRepo] savePlayerAudio: bothUploaded=$bothUploaded');
      return bothUploaded;
    } catch (e) {
      debugPrint('[VoiceRepo] savePlayerAudio error: $e');
      rethrow;
    }
  }

  /// Streams a single voice memory document for real-time updates.
  static Stream<VoiceMemory?> streamMemory(
    String gameId,
    String memoryId,
  ) {
    return _voiceMemoriesRef(gameId).doc(memoryId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return VoiceMemory.fromMap(
        snap.data() as Map<String, dynamic>,
        snap.id,
      );
    });
  }

  /// Marks one player as having saved the memory permanently.
  static Future<bool> savePermanently(
    String gameId,
    String memoryId,
    String playerId,
  ) async {
    try {
      final snap = await _voiceMemoriesRef(gameId).doc(memoryId).get();
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>;
      if (data['player1Id'] == playerId) {
        await snap.reference.update({'savedByPlayer1': true});
      } else if (data['player2Id'] == playerId) {
        await snap.reference.update({'savedByPlayer2': true});
      } else {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves a voice memory from games/{gameId}/voice_memories/{memoryId}.
  static Future<VoiceMemory?> getVoiceMemory(
    String gameId,
    String memoryId,
  ) async {
    try {
      final doc =
          await _voiceMemoriesRef(gameId).doc(memoryId).get();
      if (!doc.exists || doc.data() == null) return null;
      return VoiceMemory.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Streams all voice memories for a couple across all games using a
  /// collection-group query on the voice_memories subcollection.
  static Stream<List<VoiceMemory>> streamForCouple(String coupleId) {
    return _db
        .collectionGroup('voice_memories')
        .where('coupleId', isEqualTo: coupleId)
        .where('pending', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => VoiceMemory.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Deletes a voice memory from games/{gameId}/voice_memories/{memoryId}.
  ///
  /// Solo funcional con Firebase Blaze: firestore.rules tiene
  /// `allow delete: if false` en voice_memories, así que el cliente no puede
  /// borrar (el borrado lo hace la Cloud Function con admin SDK). En modo beta
  /// (BetaConfig.isBetaEnabled) este método queda inactivo y no se llama.
  static Future<bool> deleteVoiceMemory(
    String gameId,
    String memoryId,
  ) async {
    try {
      await _voiceMemoriesRef(gameId).doc(memoryId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
