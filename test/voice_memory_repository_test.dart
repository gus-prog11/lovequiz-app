import 'package:LoveQuiz/features/voice_memories/repositories/voice_memory_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gameId = 'game-1';
  const coupleId = 'couple-1';
  const memoryId = 'memory-1';
  const question = '¿Cuál es tu recuerdo favorito?';

  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    VoiceMemoryRepository.dbForTesting = firestore;
  });

  group('savePlayerAudio', () {
    test('crea el documento con los campos base cuando el primer jugador sube',
        () async {
      final bothUploaded = await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );

      expect(bothUploaded, isFalse);

      final doc = await firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['coupleId'], coupleId);
      expect(data['question'], question);
      expect(data['player1Id'], 'p1');
      expect(data['player1AudioUrl'], 'https://cdn/audio-p1');
      expect(data['player2AudioUrl'] as String?, isNull,
          reason: 'El segundo jugador aún no ha subido');
      expect(data['pending'], isTrue);
      expect(data['savedByPlayer1'], isFalse);
      expect(data['createdAt'], isNotNull);
      expect(data['expiresAt'], isNotNull);
    });

    test('devuelve true y cierra el pendiente cuando ambos jugadores suben',
        () async {
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );

      final bothUploaded = await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player2Id: 'p2',
        player2AudioUrl: 'https://cdn/audio-p2',
      );

      expect(bothUploaded, isTrue);

      final doc = await firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      final data = doc.data()!;
      expect(data['player1AudioUrl'], 'https://cdn/audio-p1');
      expect(data['player2AudioUrl'], 'https://cdn/audio-p2');
      expect(data['pending'], isFalse);
      expect(
        data['displayTitle'],
        startsWith('Recuerdo del '),
        reason: 'El título se genera al cerrar el recuerdo',
      );
    });

    test('el segundo jugador no pisa los campos del primero', () async {
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );

      final createdBefore = await firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      final createdAt = createdBefore.data()!['createdAt'];

      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player2Id: 'p2',
        player2AudioUrl: 'https://cdn/audio-p2',
      );

      final doc = await firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      final data = doc.data()!;
      expect(data['player1Id'], 'p1');
      expect(data['player1AudioUrl'], 'https://cdn/audio-p1');
      expect(data['createdAt'], createdAt,
          reason: 'Los campos base no deben sobrescribirse');
    });

    test('dos partidas distintas escriben en documentos separados', () async {
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: 'game-2',
        coupleId: coupleId,
        question: question,
        player2Id: 'p2',
        player2AudioUrl: 'https://cdn/audio-p2',
      );

      final snap = await firestore
          .collection('games')
          .doc('game-2')
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      expect(snap.exists, isTrue);
      expect(snap.data()!['player2AudioUrl'], 'https://cdn/audio-p2');
      expect(snap.data()!['player1AudioUrl'] as String?, isNull);
    });
  });

  group('savePermanently', () {
    Future<void> seedMemory() async {
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player2Id: 'p2',
        player2AudioUrl: 'https://cdn/audio-p2',
      );
    }

    test('marca al jugador correcto', () async {
      await seedMemory();

      final p1 = await VoiceMemoryRepository.savePermanently(
          gameId, memoryId, 'p1');
      expect(p1, isTrue);

      final doc = await firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      expect(doc.data()!['savedByPlayer1'], isTrue);
      expect(doc.data()!['savedByPlayer2'], isFalse);
    });

    test('devuelve false para un jugador que no participó', () async {
      await seedMemory();

      final result =
          await VoiceMemoryRepository.savePermanently(gameId, memoryId, 'x');
      expect(result, isFalse);
    });

    test('devuelve false si el documento no existe', () async {
      final result =
          await VoiceMemoryRepository.savePermanently(gameId, 'missing', 'p1');
      expect(result, isFalse);
    });
  });

  group('getVoiceMemory', () {
    test('recupera una memoria guardada', () async {
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );

      final memory = await VoiceMemoryRepository.getVoiceMemory(gameId, memoryId);

      expect(memory, isNotNull);
      expect(memory!.id, memoryId);
      expect(memory.gameId, gameId);
      expect(memory.coupleId, coupleId);
      expect(memory.question, question);
    });

    test('devuelve null si no existe', () async {
      final memory = await VoiceMemoryRepository.getVoiceMemory(gameId, 'nope');
      expect(memory, isNull);
    });
  });

  group('streamForCouple', () {
    test('solo devuelve memorias no pendientes de la pareja, ordenadas', () async {
      final ref = firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories');

      await ref.doc('m1').set({
        'coupleId': coupleId,
        'pending': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'player1AudioUrl': 'a',
        'player2AudioUrl': 'b',
      });
      await ref.doc('m2').set({
        'coupleId': coupleId,
        'pending': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
        'player1AudioUrl': 'a',
        'player2AudioUrl': 'b',
      });
      await ref.doc('m3').set({
        'coupleId': coupleId,
        'pending': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'player1AudioUrl': '',
        'player2AudioUrl': '',
      });
      await ref.doc('m4').set({
        'coupleId': 'other-couple',
        'pending': false,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 4)),
        'player1AudioUrl': 'a',
        'player2AudioUrl': 'b',
      });

      final memories = await VoiceMemoryRepository.streamForCouple(coupleId)
          .first;

      expect(memories.map((m) => m.id), ['m2', 'm1'],
          reason: 'Descarta pendientes y memorias de otras parejas y ordena');
      expect(memories.map((m) => m.isPermanent), everyElement(isFalse));
    });
  });

  group('deleteVoiceMemory', () {
    test('elimina la memoria', () async {
      await VoiceMemoryRepository.savePlayerAudio(
        memoryId: memoryId,
        gameId: gameId,
        coupleId: coupleId,
        question: question,
        player1Id: 'p1',
        player1AudioUrl: 'https://cdn/audio-p1',
      );

      final ok = await VoiceMemoryRepository.deleteVoiceMemory(gameId, memoryId);
      expect(ok, isTrue);

      final doc = await firestore
          .collection('games')
          .doc(gameId)
          .collection('voice_memories')
          .doc(memoryId)
          .get();
      expect(doc.exists, isFalse);
    });
  });
}
