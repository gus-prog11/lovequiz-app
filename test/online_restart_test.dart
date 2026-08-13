import 'dart:math';

import 'package:LoveQuiz/features/game_engine/data/engine_match_codec.dart';
import 'package:LoveQuiz/features/game_engine/data/online_restart_bridge.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildOnlineRestartUpdate', () {
    test('resetea contadores y limpia comparaciones', () {
      final update = buildOnlineRestartUpdate(engineRounds: const []);
      expect(update['currentQuestion'], 0);
      expect(update['turn'], 0);
      expect(update['status'], 'playing');
      expect(update['comparisonP1'], isNull);
      expect(update['comparisonP2'], isNull);
    });

    test('incluye engineRounds cuando el host reinicia con motor', () {
      final update = buildOnlineRestartUpdate(
        engineRounds: [
          {'chapter': 'bienvenida', 'emotion': 'diversion'},
        ],
      );
      expect(update['engineRounds'], isA<List>());
      expect(update['engineRounds'], hasLength(1));
    });
  });

  group('restart online con engineRounds', () {
    test('el host publica un recorrido nuevo de 25 rondas', () async {
      final rounds = await buildEngineMatch(random: Random(21));
      expect(rounds, hasLength(25));

      final sala = buildOnlineRestartUpdate(
        engineRounds: encodeEngineMatch(rounds),
      );

      expect(sala['engineRounds'], isA<List>());
      expect((sala['engineRounds'] as List), hasLength(25));
      expect(sala['status'], 'playing');
      expect(sala['currentQuestion'], 0);
    });

    test('conserva voz, retos y comparaciones en el recorrido reiniciado',
        () async {
      final rounds = await buildEngineMatch(random: Random(4));

      expect(
        rounds.any((r) => r.question?.type == QuestionType.voz),
        isTrue,
        reason: 'debe incluir momento especial de voz',
      );
      expect(
        rounds.any((r) => r.question?.type == QuestionType.reto),
        isTrue,
        reason: 'debe incluir retos',
      );
      expect(
        rounds.any((r) => r.question?.type == QuestionType.comparacion),
        isTrue,
        reason: 'debe incluir comparaciones',
      );
    });

    test('un segundo restart genera un recorrido distinto (no reutiliza el anterior)',
        () async {
      final first = await buildEngineMatch(random: Random(1));
      final second = await buildEngineMatch(random: Random(2));

      final firstIds = first.map((r) => r.question!.id).toList();
      final secondIds = second.map((r) => r.question!.id).toList();
      expect(firstIds, isNot(equals(secondIds)));
    });
  });

  group('host e invitado reconstruyen el mismo recorrido', () {
    test('parseOnlineRestartContent reproduce mapa a mapa el del host', () async {
      final hostRounds = await buildEngineMatch(random: Random(12));
      final sala = {
        'status': 'playing',
        'currentQuestion': 0,
        'turn': 0,
        'categories': ['romanticas'],
        'engineRounds': encodeEngineMatch(hostRounds),
      };

      final guestContent = parseOnlineRestartContent(sala);

      expect(guestContent.usesEngine, isTrue);
      expect(guestContent.engineRounds, hasLength(25));
      expect(
        guestContent.engineRounds.map((r) => r.toMap()).toList(),
        hostRounds.map((r) => r.toMap()).toList(),
      );
      expect(
        guestContent.engineRounds.any(
          (r) => r.question?.type == QuestionType.comparacion,
        ),
        isTrue,
      );
    });

    test('solo el host genera: el invitado nunca llama buildEngineMatch', () {
      // El flujo de restart online delega la generación al host; el invitado
      // solo decodifica engineRounds del snapshot (sin Random propio).
      final sala = {
        'engineRounds': encodeEngineMatch(const []),
        'status': 'playing',
      };
      expect(roomHasEngineMatch(sala), isFalse);

      final hostPayload = buildOnlineRestartUpdate(
        engineRounds: encodeEngineMatch(const []),
      );
      expect(hostPayload.containsKey('engineRounds'), isTrue);
    });
  });

  group('categorías se conservan en el restart', () {
    test('modo temático romanticas mantiene el tema en el recorrido reiniciado',
        () async {
      const categories = ['romanticas'];
      final preferred = categories
          .map(
            (id) => QuestionCategory.values.firstWhere((c) => c.name == id),
          )
          .toList();

      final rounds = await buildEngineMatch(
        preferredCategories: preferred,
        random: Random(7),
      );

      expect(rounds, hasLength(25));
      expect(
        rounds.every((r) => r.enforceCategory),
        isTrue,
        reason: 'modo temático debe marcar enforceCategory',
      );

      final themedCount = rounds
          .where((r) => r.question!.category == QuestionCategory.romanticas)
          .length;
      expect(themedCount, greaterThanOrEqualTo(20));

      final climax = rounds.where((r) => r.chapter == Chapter.momentoEspecial);
      expect(climax.single.question!.category, QuestionCategory.romanticas);
    });

    test('el snapshot de sala conserva categories sin borrarlas en el update',
        () async {
      final rounds = await buildEngineMatch(
        preferredCategories: const [QuestionCategory.calientes],
        random: Random(9),
      );
      final sala = <String, dynamic>{
        'categories': ['calientes'],
        'timerSeconds': 30,
        'engineRounds': encodeEngineMatch(rounds),
      };

      // buildOnlineRestartUpdate no modifica categories (permanecen en sala).
      final restartFields = buildOnlineRestartUpdate(
        engineRounds: sala['engineRounds'] as List<Map<String, dynamic>>,
      );
      sala.addAll(restartFields);

      expect(sala['categories'], ['calientes']);
      expect(sala['timerSeconds'], 30);

      final content = parseOnlineRestartContent(sala);
      expect(
        content.engineRounds.every((r) => r.enforceCategory),
        isTrue,
      );
    });
  });
}
