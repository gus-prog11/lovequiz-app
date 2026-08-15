import 'package:LoveQuiz/models/social_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SocialService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Envía una solicitud de amistad a otro usuario.
  static Future<void> sendFriendRequest(String targetUid) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final alias = userDoc.data()?['alias'] ?? 'Usuario';
    final invId = '${_uid}_$targetUid';
    await _db
        .collection('users')
        .doc(targetUid)
        .collection('invitations')
        .doc(invId)
        .set(
          InvitationModel(
            id: invId,
            fromUid: _uid,
            fromAlias: alias,
            toUid: targetUid,
            createdAt: DateTime.now(),
          ).toMap(),
        );
  }

  // Escucha las solicitudes de amistad pendientes en tiempo real.
  static Stream<QuerySnapshot> invitationsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('invitations')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Acepta una solicitud de amistad y crea la relación mutua.
  //
  // Las tres escrituras críticas (amigo mío, amigo recíproco, invitación a
  // `accepted`) van en un MISMO WriteBatch: si una falla, no aplica ninguna.
  // Antes, si el write recíproco fallaba a mitad, quedaba una amistad de una
  // sola vía con la invitación todavía `pending` (R10).
  static Future<void> acceptInvitation(String invId) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('invitations')
        .doc(invId)
        .get();
    if (!doc.exists) return;
    final inv = InvitationModel.fromMap(doc.data()!);

    // Guarda contra doble aceptación concurrente: si ya se marcó accepted,
    // no re-ejecutar (los sets de amigos son idempotentes, pero el recuento
    // no debe duplicarse).
    if (inv.status == 'accepted') return;

    final now = DateTime.now();
    final myDoc = await _db.collection('users').doc(_uid).get();
    final myAlias = myDoc.data()?['alias'] ?? 'Usuario';

    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(_uid).collection('friends').doc(inv.fromUid),
      FriendModel(
        uid: inv.fromUid,
        alias: inv.fromAlias,
        status: 'accepted',
        since: now,
      ).toMap(),
    );
    batch.set(
      _db
          .collection('users')
          .doc(inv.fromUid)
          .collection('friends')
          .doc(_uid),
      FriendModel(
        uid: _uid,
        alias: myAlias,
        status: 'accepted',
        since: now,
      ).toMap(),
    );
    batch.update(
      _db
          .collection('users')
          .doc(_uid)
          .collection('invitations')
          .doc(invId),
      {'status': 'accepted'},
    );
    await batch.commit();

    // Recuento de amigos: cosmético, va fuera del batch (requiere leer
    // primero). Si falla no rompe la amistad, que ya quedó atómica.
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();
      await _db.collection('users').doc(_uid).update({
        'totalFriends': snapshot.docs.length,
      });
    } catch (e) {
      debugPrint('[SocialService] totalFriends update failed: $e');
    }
  }

  // Rechaza una solicitud de amistad recibida.
  static Future<void> rejectInvitation(String invId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('invitations')
        .doc(invId)
        .update({'status': 'rejected'});
  }

  // Escucha la lista de amigos aceptados en tiempo real.
  static Stream<QuerySnapshot> friendsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  // Busca usuarios por alias y retorna sus datos.
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _db
        .collection('users')
        .orderBy('alias')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    return snapshot.docs
        .where((doc) => doc.id != _uid)
        .map((doc) => {'uid': doc.id, 'alias': doc.data()['alias'] ?? ''})
        .toList();
  }

  // Obtiene el total de amigos aceptados del usuario.
  static Future<int> getFriendCount() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .get();
    return snapshot.docs.length;
  }

  // Obtiene las estadísticas de juego del usuario.
  static Future<GameStats> getGameStats() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return GameStats();
    final data = doc.data()!;
    return GameStats(
      totalGames: data['totalGames'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      totalMinutes: data['totalMinutes'] ?? 0,
      currentStreak: data['streak']?['currentStreak'] ?? 0,
      longestStreak: data['streak']?['longestStreak'] ?? 0,
      totalFriends: data['totalFriends'] ?? 0,
    );
  }
}
