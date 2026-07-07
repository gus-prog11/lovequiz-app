import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  static Future<String> createRoom({bool isRandom = false}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("No hay un usuario autenticado");
    }

    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    final hostName = userDoc.data()?['alias'] ?? "Jugador";
    var code = _generateRoomCode();
    bool exists = (await _db.collection('rooms').doc(code).get()).exists;
    while (exists) {
      code = _generateRoomCode();
      exists = (await _db.collection('rooms').doc(code).get()).exists;
    }
    await _db.collection('rooms').doc(code).set({
      'hostName': hostName,
      'guestName': null,
      'status': 'waiting',
      'isRandom': isRandom,
      'categories': <String>[],
      'timerSeconds': 0,
      'currentQuestion': 0,
      'turn': 0,
      'totalQuestions': 30,
      'questions': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  static Future<bool> joinRoom(String code) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("No hay usuario");
    }

    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    final guestName = userDoc.data()?['alias'] ?? "Jugador";
    final doc = await _db.collection('rooms').doc(code).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    if (data['guestName'] != null) return false;
    if (data['status'] != 'waiting') return false;
    await _db.collection('rooms').doc(code).update({'guestName': guestName});
    return true;
  }

  static Future<String?> findRandomRoom() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("No hay usuario");
    }

    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    final guestName = userDoc.data()?['alias'] ?? "Jugador";
    final snapshot = await _db
        .collection('rooms')
        .where('status', isEqualTo: 'waiting')
        .where('isRandom', isEqualTo: true)
        .where('guestName', isEqualTo: null)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    if (data['hostName'] == guestName) return null;
    return doc.id;
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> roomStream(
    String code,
  ) {
    return _db.collection('rooms').doc(code).snapshots();
  }

  static Future<void> updateGameConfig(
    String code,
    List<String> categories,
    int timerSeconds,
    int totalQuestions, {
    List<Map<String, dynamic>>? questions,
  }) async {
    await _db.collection('rooms').doc(code).update({
      'categories': categories,
      'timerSeconds': timerSeconds,
      'totalQuestions': totalQuestions,
      'currentQuestion': 0,
      'turn': 0,
      'status': 'playing',
      'questions': questions ?? [],
    });
  }

  static Future<void> saveQuestions(
    String code,
    List<Map<String, dynamic>> questions,
  ) async {
    await _db.collection('rooms').doc(code).update({'questions': questions});
  }

  static Future<void> nextQuestion(
    String code,
    int currentQuestion,
    int turn,
  ) async {
    await _db.collection('rooms').doc(code).update({
      'currentQuestion': currentQuestion,
      'turn': turn,
    });
  }

  static Future<void> setupRoom(String code) async {
    await _db.collection('rooms').doc(code).update({'status': 'setup'});
  }

  static Future<void> finishGame(String code) async {
    await _db.collection('rooms').doc(code).update({'status': 'finished'});
  }

  static Future<void> restartGame(String code) async {
    await _db.collection('rooms').doc(code).update({
      'currentQuestion': 0,
      'turn': 0,
      'status': 'playing',
    });
  }

  static Future<void> deleteRoom(String code) async {
    await _db.collection('rooms').doc(code).delete();
  }

  static Future<void> saveGameHistory({
    required String player1,
    required String player2,
    required String mode,
    required List<String> categories,
    required int questionsAnswered,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    await _db.collection("game_history").add({
      'userId': user.uid,
      'player1': player1,
      'player2': player2,
      'mode': mode,
      'categories': categories,
      'questionsAnswered': questionsAnswered,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserHistory() {
    final user = FirebaseAuth.instance.currentUser;

    return _db
        .collection('game_history')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Obtiene el ID del usuario que no es el actual en la sala
  /// Retorna null si solo hay un usuario o si hay error
  static Future<String?> getOtherPlayerId(String roomCode) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return null;

      final roomDoc = await _db.collection('rooms').doc(roomCode).get();
      if (!roomDoc.exists) return null;

      // Aquí asumimos que los usuarios están en una colección de jugadores
      // o en el documento principal. Adjustar según tu estructura real.
      return null;
    } catch (e) {
      print('Error getting other player: $e');
      return null;
    }
  }

  /// Stream que monitorea si el otro jugador está conectado
  static Stream<bool> monitorOtherPlayerConnection(
    String roomCode,
    String otherPlayerId,
  ) {
    const presenceTimeoutSeconds = 30;

    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('presence')
        .doc(otherPlayerId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;

          final data = snapshot.data();
          if (data == null) return false;

          final lastSeen = data['lastSeen'] as Timestamp?;
          if (lastSeen == null) return false;

          final now = DateTime.now();
          final lastSeenTime = lastSeen.toDate();
          final diffSeconds = now.difference(lastSeenTime).inSeconds;

          return diffSeconds < presenceTimeoutSeconds;
        });
  }
}
