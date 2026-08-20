import 'package:LoveQuiz/models/emotional_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmotionalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference _collection(String type) =>
      _db.collection('users').doc(_uid).collection(type);

  static CollectionReference _coupleCollection(String coupleId, String type) =>
      _db.collection('couples').doc(coupleId).collection(type);

  // Guarda un recuerdo emocional del usuario en Firestore.
  static Future<void> saveMemory(MemoryModel memory) async {
    await _collection('memories').doc(memory.id).set(memory.toMap());
  }

  // Obtiene la lista de recuerdos, opcionalmente filtrados por tipo.
  static Future<List<MemoryModel>> getMemories({String? type}) async {
    Query query = _collection(
      'memories',
    ).orderBy('createdAt', descending: true);
    if (type != null) query = query.where('type', isEqualTo: type);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MemoryModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Escucha los recuerdos en tiempo real, filtrados por tipo.
  static Stream<QuerySnapshot> memoriesStream({String? type}) {
    Query query = _collection(
      'memories',
    ).orderBy('createdAt', descending: true);
    if (type != null) query = query.where('type', isEqualTo: type);
    return query.snapshots();
  }

  // Elimina un recuerdo emocional por su ID.
  static Future<void> deleteMemory(String id) async {
    await _collection('memories').doc(id).delete();
  }

  // Marca o desmarca un recuerdo como favorito.
  static Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _collection('memories').doc(id).update({'isFavorite': isFavorite});
  }

  // Guarda una respuesta favorita en el perfil de pareja.
  static Future<void> saveFavoriteAnswer(FavoriteAnswer answer) async {
    final coupleId = answer.coupleId;
    if (coupleId.isEmpty) return;
    await _coupleCollection(
      coupleId,
      'favorite_answers',
    ).doc(answer.id).set(answer.toMap());
  }

  // Escucha las respuestas favoritas de una pareja en tiempo real.
  static Stream<QuerySnapshot> favoriteAnswersStream(String coupleId) {
    return _coupleCollection(
      coupleId,
      'favorite_answers',
    ).orderBy('createdAt', descending: true).snapshots();
  }

  // Elimina una respuesta favorita de una pareja.
  static Future<void> deleteFavoriteAnswer(String id, String coupleId) async {
    await _coupleCollection(coupleId, 'favorite_answers').doc(id).delete();
  }

  // Verifica si una respuesta ya está guardada como favorita para una pareja.
  static Future<bool> isAnswerFavorited({
    required String coupleId,
    required String question,
    required String answer,
  }) async {
    final snap = await _coupleCollection(
      coupleId,
      'favorite_answers',
    ).where('question', isEqualTo: question)
        .where('answer', isEqualTo: answer)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Elimina una respuesta favorita que coincida con pregunta + respuesta.
  static Future<void> deleteFavoriteByContent({
    required String coupleId,
    required String question,
    required String answer,
  }) async {
    final snap = await _coupleCollection(
      coupleId,
      'favorite_answers',
    ).where('question', isEqualTo: question)
        .where('answer', isEqualTo: answer)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // Genera un ID único para un nuevo recuerdo.
  static Future<String> generateMemoryId() async {
    final ref = _collection('memories').doc();
    return ref.id;
  }

  // Genera un ID único para una respuesta favorita.
  static Future<String> generateFavoriteAnswerId() async {
    final ref = _db
        .collection('couples')
        .doc('_')
        .collection('favorite_answers')
        .doc();
    return ref.id;
  }
}
