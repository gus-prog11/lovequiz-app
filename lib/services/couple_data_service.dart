import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovequiz_app/models/couple_models.dart';

/// Servicio para gestionar datos compartidos de parejas
class CoupleDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ─── PAREJA (Couple Profile) ─────────────────────────────────────────────

  /// Obtiene o crea el perfil de pareja del usuario
  static Future<CoupleProfile?> getCoupleProfile() async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final partnerId = userDoc.data()?['partnerId'];

      if (partnerId == null) return null;

      final coupleId = _generateCoupleId(_uid, partnerId);
      final doc = await _db.collection('couples').doc(coupleId).get();

      if (doc.exists) {
        return CoupleProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting couple profile: $e');
      return null;
    }
  }

  /// Stream de perfil de pareja
  static Stream<CoupleProfile?> coupleProfileStream() {
    return _db.collection('users').doc(_uid).snapshots().asyncMap((
      userDoc,
    ) async {
      final partnerId = userDoc.data()?['partnerId'];
      if (partnerId == null) return null;

      final coupleId = _generateCoupleId(_uid, partnerId);
      final coupleDoc = await _db.collection('couples').doc(coupleId).get();

      if (coupleDoc.exists) {
        return CoupleProfile.fromMap(coupleDoc.data()!);
      }
      return null;
    });
  }

  /// Conecta a dos usuarios como pareja
  static Future<CoupleProfile> createCoupleProfile(
    String partnerId,
    String user1Name,
    String user2Name,
    String user1Photo,
    String user2Photo,
    DateTime startDate,
  ) async {
    final coupleId = _generateCoupleId(_uid, partnerId);
    final now = Timestamp.now();

    final profile = CoupleProfile(
      coupleId: coupleId,
      user1Id: _uid,
      user2Id: partnerId,
      user1Name: user1Name,
      user2Name: user2Name,
      user1Photo: user1Photo,
      user2Photo: user2Photo,
      startDate: Timestamp.fromDate(startDate),
      status: 'connected',
      createdAt: now,
    );

    await _db.collection('couples').doc(coupleId).set(profile.toMap());

    // Guardar el ID de pareja en ambos usuarios
    await _db.collection('users').doc(_uid).update({'coupleId': coupleId});
    await _db.collection('users').doc(partnerId).update({'coupleId': coupleId});

    return profile;
  }

  // ─── RECUERDOS (Memories) ───────────────────────────────────────────────

  /// Agrega un nuevo recuerdo a la pareja
  static Future<void> addMemory({
    required String coupleId,
    required String title,
    required String description,
    required List<String> photoUrls,
    String category = 'moment',
  }) async {
    final id = FirebaseFirestore.instance.collection('_').doc().id;
    final memory = Memory(
      id: id,
      coupleId: coupleId,
      uploadedBy: _uid,
      title: title,
      description: description,
      photoUrls: photoUrls,
      category: category,
      createdAt: Timestamp.now(),
    );

    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .doc(id)
        .set(memory.toMap());
  }

  /// Stream de recuerdos de la pareja
  static Stream<List<Memory>> memoriesStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) => Memory.fromMap(doc.data())).toList();
        });
  }

  // ─── FRASES QUE LOS DEFINEN ─────────────────────────────────────────────

  /// Agrega una frase que define a la pareja
  static Future<void> addDefiningPhrase(
    String coupleId,
    String phrase,
    String author,
  ) async {
    final id = FirebaseFirestore.instance.collection('_').doc().id;
    final defPhrase = DefiningPhrase(
      id: id,
      coupleId: coupleId,
      createdBy: _uid,
      phrase: phrase,
      author: author,
      createdAt: Timestamp.now(),
    );

    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('defining_phrases')
        .doc(id)
        .set(defPhrase.toMap());
  }

  /// Stream de frases que definen
  static Stream<List<DefiningPhrase>> definingPhrasesStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('defining_phrases')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => DefiningPhrase.fromMap(doc.data()))
              .toList();
        });
  }

  // ─── PROMESAS ───────────────────────────────────────────────────────────

  /// Agrega una promesa
  static Future<void> addPromise(String coupleId, String promise) async {
    final id = FirebaseFirestore.instance.collection('_').doc().id;
    final newPromise = Promise(
      id: id,
      coupleId: coupleId,
      createdBy: _uid,
      promise: promise,
      createdAt: Timestamp.now(),
    );

    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('promises')
        .doc(id)
        .set(newPromise.toMap());
  }

  /// Marca una promesa como completada
  static Future<void> completePromise(String coupleId, String promiseId) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('promises')
        .doc(promiseId)
        .update({'completed': true, 'completedAt': Timestamp.now()});
  }

  /// Stream de promesas
  static Stream<List<Promise>> promisesStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('promises')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) => Promise.fromMap(doc.data())).toList();
        });
  }

  // ─── EVENTOS ESPECIALES ──────────────────────────────────────────────────

  /// Agrega un evento especial
  static Future<void> addSpecialEvent({
    required String coupleId,
    required String title,
    required String description,
    required DateTime eventDate,
    String emoji = '💕',
    String? photoUrl,
  }) async {
    final id = FirebaseFirestore.instance.collection('_').doc().id;
    final event = SpecialEvent(
      id: id,
      coupleId: coupleId,
      title: title,
      description: description,
      emoji: emoji,
      eventDate: Timestamp.fromDate(eventDate),
      photoUrl: photoUrl,
      createdAt: Timestamp.now(),
    );

    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('special_events')
        .doc(id)
        .set(event.toMap());
  }

  /// Stream de eventos especiales ordenados por fecha
  static Stream<List<SpecialEvent>> specialEventsStream(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('special_events')
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => SpecialEvent.fromMap(doc.data()))
              .toList();
        });
  }

  // ─── UTILIDADES ─────────────────────────────────────────────────────────

  /// Genera un ID único para una pareja basado en los IDs de usuarios
  static String _generateCoupleId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Obtiene la información de la pareja (ambos usuarios)
  static Future<(String, String)> getCoupleUserNames(String coupleId) async {
    try {
      final doc = await _db.collection('couples').doc(coupleId).get();
      final data = doc.data();
      if (data != null) {
        return (
          data['user1Name'] as String? ?? 'Usuario',
          data['user2Name'] as String? ?? 'Pareja',
        );
      }
      return ('Usuario', 'Pareja');
    } catch (e) {
      return ('Usuario', 'Pareja');
    }
  }

  /// Calcula días juntos
  static int getDaysTogether(Timestamp startDate) {
    final now = DateTime.now();
    final startDt = startDate.toDate();
    return now.difference(startDt).inDays;
  }

  /// Elimina un recuerdo
  static Future<void> deleteMemory(String coupleId, String memoryId) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .doc(memoryId)
        .delete();
  }

  /// Elimina una frase
  static Future<void> deleteDefiningPhrase(
    String coupleId,
    String phraseId,
  ) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('defining_phrases')
        .doc(phraseId)
        .delete();
  }

  /// Elimina una promesa
  static Future<void> deletePromise(String coupleId, String promiseId) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('promises')
        .doc(promiseId)
        .delete();
  }

  /// Elimina un evento especial
  static Future<void> deleteSpecialEvent(
    String coupleId,
    String eventId,
  ) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('special_events')
        .doc(eventId)
        .delete();
  }
}
