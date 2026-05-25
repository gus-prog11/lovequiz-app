import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  static Future<String> createRoom(String hostName, {bool isRandom = false}) async {
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
      'totalQuestions': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  static Future<bool> joinRoom(String code, String guestName) async {
    final doc = await _db.collection('rooms').doc(code).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    if (data['guestName'] != null) return false;
    if (data['status'] != 'waiting') return false;
    await _db.collection('rooms').doc(code).update({
      'guestName': guestName,
    });
    return true;
  }

  static Future<String?> findRandomRoom(String myName) async {
    final snapshot = await _db
        .collection('rooms')
        .where('status', isEqualTo: 'waiting')
        .where('isRandom', isEqualTo: true)
        .where('guestName', isEqualTo: null)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    if (doc.data()['hostName'] == myName) return null;
    return doc.id;
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> roomStream(String code) {
    return _db.collection('rooms').doc(code).snapshots();
  }

  static Future<void> updateGameConfig(String code, List<String> categories, int timerSeconds, int totalQuestions) async {
    await _db.collection('rooms').doc(code).update({
      'categories': categories,
      'timerSeconds': timerSeconds,
      'totalQuestions': totalQuestions,
      'currentQuestion': 0,
      'turn': 0,
      'status': 'playing',
      'questions': [],
    });
  }

  static Future<void> saveQuestions(String code, List<Map<String, String>> questions) async {
    await _db.collection('rooms').doc(code).update({
      'questions': questions,
    });
  }

  static Future<void> nextQuestion(String code, int currentQuestion, int turn) async {
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
}
