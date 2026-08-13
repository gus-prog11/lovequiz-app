import 'dart:async';
import 'package:LoveQuiz/models/couple_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para gestionar datos compartidos de parejas
class CoupleDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ─── PAREJA (Couple Profile) ─────────────────────────────────────────────

  /// Obtiene o crea el perfil de pareja del usuario
  // Obtiene el perfil de pareja del usuario actual.
  static Future<CoupleProfile?> getCoupleProfile() async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      if (userData == null) return null;

      // Buscar por partnerId o coupleId
      final partnerId = userData['partnerId'] as String?;
      final storedCoupleId = userData['coupleId'] as String?;

      String? coupleId;
      if (storedCoupleId != null) {
        coupleId = storedCoupleId;
      } else if (partnerId != null) {
        coupleId = _generateCoupleId(_uid, partnerId);
      }

      if (coupleId == null) return null;

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
  // Escucha en tiempo real el perfil de pareja. Se reactiva tanto cuando
  // cambia el documento del usuario como cuando cambia el documento de la
  // pareja (p. ej. la otra persona actualiza su foto).
  static Stream<CoupleProfile?> coupleProfileStream() {
    final controller = StreamController<CoupleProfile?>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? coupleSub;
    String? currentCoupleId;

    final userSub = _db.collection('users').doc(_uid).snapshots().listen((
      userDoc,
    ) {
      if (controller.isClosed) return;
      final userData = userDoc.data();
      if (userData == null) {
        controller.add(null);
        return;
      }

      final partnerId = userData['partnerId'] as String?;
      final storedCoupleId = userData['coupleId'] as String?;

      String? coupleId;
      if (storedCoupleId != null) {
        coupleId = storedCoupleId;
      } else if (partnerId != null) {
        coupleId = _generateCoupleId(_uid, partnerId);
      }

      if (coupleId == null) {
        controller.add(null);
        return;
      }

      if (coupleId != currentCoupleId) {
        coupleSub?.cancel();
        currentCoupleId = coupleId;
        coupleSub = _db.collection('couples').doc(coupleId).snapshots().listen((
          coupleDoc,
        ) {
          if (!controller.isClosed) {
            controller.add(
              coupleDoc.exists
                  ? CoupleProfile.fromMap(coupleDoc.data()!)
                  : null,
            );
          }
        });
      }
    });

    controller.onCancel = () {
      userSub.cancel();
      coupleSub?.cancel();
    };

    return controller.stream;
  }

  /// Sincroniza nombres y fotos del perfil de pareja con los datos actuales
  /// de ambos usuarios. Actualiza el documento de la pareja si cambiaron.
  // Actualiza el documento de pareja si los nombres o fotos cambiaron.
  static Future<void> syncUserDataToCouple() async {
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      final userData = userDoc.data();
      if (userData == null) return;

      final partnerId = userData['partnerId'] as String?;
      final storedCoupleId = userData['coupleId'] as String?;
      final coupleId =
          storedCoupleId ??
          (partnerId != null ? _generateCoupleId(_uid, partnerId) : null);
      if (coupleId == null) return;

      final coupleDoc = await _db.collection('couples').doc(coupleId).get();
      if (!coupleDoc.exists) return;

      final profile = CoupleProfile.fromMap(coupleDoc.data()!);
      final currentUserName = userData['alias'] as String?;
      final currentUserPhoto = userData['photoUrl'] as String?;

      final updates = <String, dynamic>{};

      if (profile.user1Id == _uid) {
        if (currentUserName != null && currentUserName != profile.user1Name) {
          updates['user1Name'] = currentUserName;
        }
        if (currentUserPhoto != null &&
            currentUserPhoto != profile.user1Photo) {
          updates['user1Photo'] = currentUserPhoto;
        }
      } else if (profile.user2Id == _uid) {
        if (currentUserName != null && currentUserName != profile.user2Name) {
          updates['user2Name'] = currentUserName;
        }
        if (currentUserPhoto != null &&
            currentUserPhoto != profile.user2Photo) {
          updates['user2Photo'] = currentUserPhoto;
        }
      }

      final otherUserId = profile.user1Id == _uid
          ? profile.user2Id
          : profile.user1Id;
      if (otherUserId.isNotEmpty) {
        final otherDoc = await _db.collection('users').doc(otherUserId).get();
        if (otherDoc.exists) {
          final otherData = otherDoc.data()!;
          final otherName = otherData['alias'] as String?;
          final otherPhoto = otherData['photoUrl'] as String?;

          if (profile.user1Id == otherUserId) {
            if (otherName != null && otherName != profile.user1Name) {
              updates['user1Name'] = otherName;
            }
            if (otherPhoto != null && otherPhoto != profile.user1Photo) {
              updates['user1Photo'] = otherPhoto;
            }
          } else if (profile.user2Id == otherUserId) {
            if (otherName != null && otherName != profile.user2Name) {
              updates['user2Name'] = otherName;
            }
            if (otherPhoto != null && otherPhoto != profile.user2Photo) {
              updates['user2Photo'] = otherPhoto;
            }
          }
        }
      }

      if (updates.isNotEmpty) {
        await _db.collection('couples').doc(coupleId).update(updates);
      }
    } catch (e) {
      print('syncUserDataToCouple error: $e');
    }
  }

  /// Conecta a dos usuarios como pareja
  // Crea un perfil de pareja conectando a dos usuarios.
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
  // Agrega un nuevo recuerdo a la pareja.
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
  // Escucha la lista de recuerdos de la pareja en tiempo real.
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
  // Agrega una frase que define a la pareja.
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
  // Escucha las frases definitorias de la pareja en tiempo real.
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
  // Agrega una nueva promesa de la pareja.
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
  // Marca una promesa como cumplida.
  static Future<void> completePromise(String coupleId, String promiseId) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('promises')
        .doc(promiseId)
        .update({'completed': true, 'completedAt': Timestamp.now()});
  }

  /// Stream de promesas
  // Escucha la lista de promesas de la pareja en tiempo real.
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
  // Agrega un evento especial a la pareja.
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
  // Escucha los eventos especiales de la pareja en tiempo real.
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

  // ─── CÓDIGO DE ENLACE ──────────────────────────────────────────────────

  /// Genera un código de 6 caracteres para enlazar pareja
  // Genera un código de 6 caracteres para enlazar pareja.
  static Future<String> generateLinkCode() async {
    final code = _generateCode();
    await _db.collection('link_codes').doc(code).set({
      'uid': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  /// Vincula dos usuarios usando un código de enlace
  // Vincula dos usuarios usando un código de enlace.
  static Future<CoupleProfile?> linkWithCode(String code) async {
    final codeDoc = await _db.collection('link_codes').doc(code).get();
    if (!codeDoc.exists) return null;

    final partnerId = codeDoc.data()!['uid'] as String?;
    if (partnerId == null || partnerId == _uid) return null;

    // Obtener info de ambos usuarios
    final meDoc = await _db.collection('users').doc(_uid).get();
    final partnerDoc = await _db.collection('users').doc(partnerId).get();

    if (!meDoc.exists || !partnerDoc.exists) return null;

    final meData = meDoc.data()!;
    final partnerData = partnerDoc.data()!;

    final myName = meData['alias'] as String? ?? 'Yo';
    final partnerName = partnerData['alias'] as String? ?? 'Pareja';
    final myPhoto = meData['photoUrl'] as String? ?? '';
    final partnerPhoto = partnerData['photoUrl'] as String? ?? '';

    // Crear perfil de pareja
    final profile = await createCoupleProfile(
      partnerId,
      myName,
      partnerName,
      myPhoto,
      partnerPhoto,
      DateTime.now(),
    );

    // Guardar partnerId en ambos usuarios (un solo write cada uno)
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(_uid), {
      'partnerId': partnerId,
      'coupleId': profile.coupleId,
    });
    batch.update(_db.collection('users').doc(partnerId), {
      'partnerId': _uid,
      'coupleId': profile.coupleId,
    });
    await batch.commit();

    // Eliminar el código usado
    await _db.collection('link_codes').doc(code).delete();

    return profile;
  }

  // Genera un código aleatorio de 6 caracteres.
  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = DateTime.now().microsecondsSinceEpoch;
    var code = '';
    var temp = rng;
    for (var i = 0; i < 6; i++) {
      code += chars[temp % chars.length];
      temp = temp ~/ chars.length;
    }
    return code;
  }

  // ─── UTILIDADES ─────────────────────────────────────────────────────────

  /// Genera un ID único para una pareja basado en los IDs de usuarios
  // Genera un ID único para una pareja basado en ambos UIDs.
  static String _generateCoupleId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Obtiene la información de la pareja (ambos usuarios)
  // Obtiene los nombres de ambos usuarios de la pareja.
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
  // Calcula los días que llevan juntos desde una fecha.
  static int getDaysTogether(Timestamp startDate) {
    final now = DateTime.now();
    final startDt = startDate.toDate();
    return now.difference(startDt).inDays;
  }

  /// Elimina un recuerdo
  // Elimina un recuerdo de la pareja.
  static Future<void> deleteMemory(String coupleId, String memoryId) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .doc(memoryId)
        .delete();
  }

  /// Elimina una frase
  // Elimina una frase definitoria de la pareja.
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
  // Elimina una promesa de la pareja.
  static Future<void> deletePromise(String coupleId, String promiseId) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('promises')
        .doc(promiseId)
        .delete();
  }

  /// Elimina un evento especial
  // Elimina un evento especial de la pareja.
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

  // ─── DISOLVER ENLACE ────────────────────────────────────────────────────

  /// Disuelve el enlace de pareja, limpiando datos de ambos usuarios.
  static Future<void> dissolveCouple(String coupleId, String partnerId) async {
    // Limpieza best-effort de subcolecciones (mientras el doc de pareja aún
    // existe y las reglas permiten leerlas). Si falla, no bloquea la disolución.
    final subcollections = [
      'memories',
      'defining_phrases',
      'promises',
      'special_events',
      'favorite_answers',
    ];
    for (final sub in subcollections) {
      try {
        final snapshot = await _db
            .collection('couples')
            .doc(coupleId)
            .collection(sub)
            .get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }

    // Borrado atómico: se limpian ambos usuarios y el doc de pareja en el
    // MISMO batch. Si el batch entra, todo entra; nunca queda un doc zombi.
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(_uid), {
      'partnerId': FieldValue.delete(),
      'coupleId': FieldValue.delete(),
    });
    batch.update(_db.collection('users').doc(partnerId), {
      'partnerId': FieldValue.delete(),
      'coupleId': FieldValue.delete(),
    });
    batch.delete(_db.collection('couples').doc(coupleId));

    await batch.commit();

    // Invalidar códigos de enlace pendientes del dueño.
    try {
      final oldCodes = await _db
          .collection('link_codes')
          .where('uid', isEqualTo: _uid)
          .get();
      for (final doc in oldCodes.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }
}
