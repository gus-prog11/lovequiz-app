import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lovequiz_app/models/couple_models.dart';
import 'package:lovequiz_app/services/emotional_service.dart';
import 'package:lovequiz_app/models/emotional_model.dart';

class CoupleService extends ChangeNotifier {
  CoupleData _data = CoupleData();
  CoupleData get data => _data;
  bool get isLoading => _isLoading;
  bool _isLoading = true;

  StreamSubscription? _memoriesSub;
  StreamSubscription? _momentosSub;

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final userDoc = await _db.collection('users').doc(_uid).get();
    final userData = userDoc.data() ?? {};

    final now = DateTime.now();
    final createdAt = (userData['createdAt'] as Timestamp?)?.toDate() ?? now;
    final daysSinceCreation = now.difference(createdAt).inDays;
    final initialRacha = userData['streak'] ?? daysSinceCreation;

    _data = _data.copyWith(rachaJuntos: initialRacha);

    _memoriesSub = EmotionalService.memoriesStream().listen((snap) {
      final docs = snap.docs;
      _rebuildFromFirestore(docs);
    });

    final partnerId = userData['partnerId'];
    if (partnerId != null) {
      _momentosSub = _db
          .collection('users')
          .doc(partnerId)
          .collection('momentos_destacados')
          .doc('main')
          .snapshots()
          .listen((snap) {
        if (snap.exists && snap.data() != null) {
          _data = _data.copyWith(
              momentos: MomentosDestacados.fromMap(snap.data()!));
          notifyListeners();
        }
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  void _rebuildFromFirestore(List<QueryDocumentSnapshot> docs) {
    int recuerdos = 0, suenos = 0, promesas = 0;
    final timeline = <TimelineItem>[];
    for (final doc in docs) {
      final map = doc.data() as Map<String, dynamic>;
      final type = map['type'] ?? 'memory';
      if (type == 'memory') recuerdos++;
      if (type == 'dream') suenos++;
      if (type == 'promise') promesas++;
      timeline.add(TimelineItem(
        id: map['id'] ?? doc.id,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        type: type,
        createdAt: map['createdAt'] ?? Timestamp.now(),
      ));
    }
    timeline.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _data = _data.copyWith(
      recuerdosCount: recuerdos,
      suenosCount: suenos,
      promesasCount: promesas,
      timeline: timeline,
    );
    notifyListeners();
  }

  Future<void> addTimelineItem({
    required String title,
    String description = '',
    String imageUrl = '',
    required String type,
  }) async {
    final id = await EmotionalService.generateMemoryId();
    final entry = MemoryModel(
      id: id,
      userId: _uid,
      type: type,
      title: title,
      description: description,
      imageUrl: imageUrl,
      createdAt: Timestamp.now(),
      date: Timestamp.now(),
    );
    await EmotionalService.saveMemory(entry);
  }

  Future<void> saveMomentoPhoto(String field, String url) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final partnerId = userDoc.data()?['partnerId'];
    final targetUid = partnerId ?? _uid;

    await _db
        .collection('users')
        .doc(targetUid)
        .collection('momentos_destacados')
        .doc('main')
        .set({field: url}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _memoriesSub?.cancel();
    _momentosSub?.cancel();
    super.dispose();
  }
}
