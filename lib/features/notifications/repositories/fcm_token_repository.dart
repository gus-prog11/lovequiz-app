import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fcm_token.dart';

/// Registra y administra los tokens FCM del usuario.
///
/// Se soportan varios tokens por usuario (teléfono, tablet, etc.) usando una
/// subcolección users/{uid}/fcmTokens/{token}. El token funciona como ID del
/// documento, por lo que registrarlo de nuevo no crea duplicados.
class FcmTokenRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference _tokensRef(String uid) =>
      _db.collection('users').doc(uid).collection('fcmTokens');

  /// Registra o actualiza un token (upsert) para un usuario.
  static Future<void> upsertToken(String uid, String token) async {
    await _tokensRef(uid).doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Elimina un token, p. ej. cuando Firebase lo reporta como inválido.
  static Future<void> removeToken(String uid, String token) async {
    try {
      await _tokensRef(uid).doc(token).delete();
    } catch (e) {
      debugPrint('[FcmRepo] removeToken error: $e');
    }
  }

  /// Devuelve todos los tokens registrados de un usuario.
  static Future<List<FcmToken>> getTokens(String uid) async {
    final snap = await _tokensRef(uid).get();
    return snap.docs
        .map((d) => FcmToken.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}
