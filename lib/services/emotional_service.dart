import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovequiz_app/models/emotional_model.dart';

class EmotionalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference _collection(String type) =>
      _db.collection('users').doc(_uid).collection(type);

  static Future<void> saveMemory(MemoryModel memory) async {
    await _collection('memories').doc(memory.id).set(memory.toMap());
  }

  static Future<List<MemoryModel>> getMemories({String? type}) async {
    Query query = _collection('memories').orderBy('createdAt', descending: true);
    if (type != null) query = query.where('type', isEqualTo: type);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MemoryModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  static Stream<QuerySnapshot> memoriesStream({String? type}) {
    Query query = _collection('memories').orderBy('createdAt', descending: true);
    if (type != null) query = query.where('type', isEqualTo: type);
    return query.snapshots();
  }

  static Future<void> deleteMemory(String id) async {
    await _collection('memories').doc(id).delete();
  }

  static Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _collection('memories').doc(id).update({'isFavorite': isFavorite});
  }

  static Future<void> saveFavoriteAnswer(FavoriteAnswer answer) async {
    await _collection('favorite_answers').doc(answer.id).set(answer.toMap());
  }

  static Stream<QuerySnapshot> favoriteAnswersStream() {
    return _collection('favorite_answers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> deleteFavoriteAnswer(String id) async {
    await _collection('favorite_answers').doc(id).delete();
  }

  static Future<String> generateMemoryId() async {
    final ref = _collection('memories').doc();
    return ref.id;
  }

  static Future<String> generateFavoriteAnswerId() async {
    final ref = _collection('favorite_answers').doc();
    return ref.id;
  }
}
