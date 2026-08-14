import 'package:LoveQuiz/models/social_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  static Future<void> acceptInvitation(String invId) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('invitations')
        .doc(invId)
        .get();
    if (!doc.exists) return;
    final inv = InvitationModel.fromMap(doc.data()!);
    final now = DateTime.now();
    await _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .doc(inv.fromUid)
        .set(
          FriendModel(
            uid: inv.fromUid,
            alias: inv.fromAlias,
            status: 'accepted',
            since: now,
          ).toMap(),
        );
    final myDoc = await _db.collection('users').doc(_uid).get();
    final myAlias = myDoc.data()?['alias'] ?? 'Usuario';
    await _db
        .collection('users')
        .doc(inv.fromUid)
        .collection('friends')
        .doc(_uid)
        .set(
          FriendModel(
            uid: _uid,
            alias: myAlias,
            status: 'accepted',
            since: now,
          ).toMap(),
        );
    await _db
        .collection('users')
        .doc(_uid)
        .collection('invitations')
        .doc(invId)
        .update({'status': 'accepted'});
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .get();
    await _db.collection('users').doc(_uid).update({
      'totalFriends': snapshot.docs.length,
    });
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
