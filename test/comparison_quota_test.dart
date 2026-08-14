import 'dart:math';

import 'package:LoveQuiz/features/game_engine/data/question_bank_v1.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/intensity.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_question.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_round.dart';
import 'package:LoveQuiz/features/game_engine/domain/repositories/in_memory_question_repository.dart';
import 'package:LoveQuiz/features/game_engine/domain/selectors/question_selector.dart';
import 'package:LoveQuiz/features/game_engine/engine/game_engine.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('comparisonQuotaFor', () {
    test('1/2/3 comparaciones según 10/20/25 rondas', () {
      expect(comparisonQuotaFor(10), 1);
      expect(comparisonQuotaFor(15), 1);
      expect(comparisonQuotaFor(20), 2);
      expect(comparisonQuotaFor(25), 3);
      expect(comparisonQuotaFor(30), 3);
      expect(comparisonQuotaFor(9), 0);
      expect(comparisonQuotaFor(5), 0);
    });
  });

  group('banco de comparaciones (V1)', () {
    final comparaciones = bancoV1Questions
        .where((q) => q.type == QuestionType.comparacion)
        .toList();

    test('el banco es grande y variado', () {
      expect(comparaciones.length, greaterThanOrEqualTo(60),
          reason: 'se espera un banco grande de comparaciones');
    });

    test('toda comparación tiene exactamente 2 opciones válidas', () {
      for (final q in comparaciones) {
        expect(q.options.length, 2, reason: '${q.id} no tiene 2 opciones');
        expect(
          q.options.every((o) => o.isNotEmpty),
          isTrue,
          reason: '${q.id} tiene una opción vacía',
        );
      }
    });

    test('vive en Conexión o Cierre con emoción e intensidad del capítulo',
        () {
      for (final q in comparaciones) {
        expect(
          const [Chapter.conexion, Chapter.cierre],
          contains(q.chapter),
          reason: '${q.id} fuera de los capítulos de comparación',
        );
        final chapter = GameChapter.forChapter(q.chapter);
        expect(chapter.emotions, contains(q.emotion), reason: q.id);
        expect(
          q.intensity.level >= chapter.minIntensity.level &&
              q.intensity.level <= chapter.maxIntensity.level,
          isTrue,
          reason: '${q.id} con intensidad fuera de la rampa del capítulo',
        );
      }
    });

    test('ids únicos', () {
      expect(comparaciones.map((q) => q.id).toSet(), hasLength(comparaciones.length));
    });
  });

  group('la cuota aparece en las partidas del motor', () {
    test('partida de 25 rondas: al menos 3 comparaciones', () async {
      for (var seed = 1; seed <= 10; seed++) {
        final rounds = await buildEngineMatch(random: Random(seed));
        final n = rounds
            .where((r) => r.question?.type == QuestionType.comparacion)
            .length;
        expect(n, greaterThanOrEqualTo(3), reason: 'seed $seed');
      }
    });

    test('partida de 20 rondas: al menos 2 comparaciones', () async {
      for (var seed = 1; seed <= 10; seed++) {
        final rounds = await buildEngineMatch(
          totalRounds: 20,
          random: Random(seed),
        );
        final n = rounds
            .where((r) => r.question?.type == QuestionType.comparacion)
            .length;
        expect(n, greaterThanOrEqualTo(2), reason: 'seed $seed');
      }
    });

    test('partida de 10 rondas: al menos 1 comparación', () async {
      for (var seed = 1; seed <= 10; seed++) {
        final rounds = await buildEngineMatch(
          totalRounds: 10,
          random: Random(seed),
        );
        final n = rounds
            .where((r) => r.question?.type == QuestionType.comparacion)
            .length;
        expect(n, greaterThanOrEqualTo(1), reason: 'seed $seed');
      }
    });

    test('las comparaciones respetan la emoción del espacio', () async {
      final rounds = await buildEngineMatch(random: Random(7));
      for (final r in rounds) {
        if (r.question?.type == QuestionType.comparacion) {
          expect(r.question!.emotion, r.emotion,
              reason: 'la emoción del espacio es sagrada (${r.question!.id})');
        }
      }
    });

    test('la partida no se acorta por la cuota (sin huecos)', () async {
      final rounds = await buildEngineMatch(random: Random(42));
      expect(rounds, hasLength(25));
      expect(rounds.every((r) => r.question != null), isTrue);
    });

    test('modo temático: las comparaciones mantienen el tema', () async {
      for (var seed = 1; seed <= 5; seed++) {
        final rounds = await buildEngineMatch(
          preferredCategories: const [QuestionCategory.romanticas],
          random: Random(seed),
        );
        for (final r in rounds) {
          if (r.question?.type == QuestionType.comparacion) {
            expect(r.question!.category, QuestionCategory.romanticas,
                reason: 'la comparación debe ser del tema (${r.question!.id})');
          }
        }
      }
    });
  });

  group('selector en espacios forzados de comparación', () {
    test('devuelve una comparación con la emoción del espacio', () async {
      final bank = [
        _comparison('c1', Emotion.romance, Intensity.alta, QuestionCategory.romanticas),
        _comparison('c2', Emotion.romance, Intensity.media, QuestionCategory.romanticas),
        GameQuestion(
          id: 'normal',
          text: 'Normal',
          chapter: Chapter.conexion,
          emotion: Emotion.romance,
          intensity: Intensity.media,
          category: QuestionCategory.romanticas,
          type: QuestionType.conversacion,
        ),
      ];
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository(bank),
      );
      final round = GameRound(
        chapter: Chapter.conexion,
        emotion: Emotion.romance,
        intensity: Intensity.media,
        category: QuestionCategory.romanticas,
        enforceCategory: true,
        allowedTypes: const [QuestionType.comparacion],
      );

      final result = await selector.select(round: round, usedQuestionIds: {});

      expect(result, isNotNull);
      expect(result!.type, QuestionType.comparacion);
      expect(result.emotion, Emotion.romance);
      expect(result.category, QuestionCategory.romanticas);
    });

    test('sin comparación disponible devuelve null (no cambia el tipo)', () async {
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([
          GameQuestion(
            id: 'normal',
            text: 'Normal',
            chapter: Chapter.conexion,
            emotion: Emotion.romance,
            intensity: Intensity.media,
            category: QuestionCategory.romanticas,
            type: QuestionType.conversacion,
          ),
        ]),
      );
      final round = GameRound(
        chapter: Chapter.conexion,
        emotion: Emotion.romance,
        intensity: Intensity.media,
        category: QuestionCategory.romanticas,
        allowedTypes: const [QuestionType.comparacion],
      );

      final result = await selector.select(round: round, usedQuestionIds: {});

      expect(result, isNull);
    });
  });
}

GameQuestion _comparison(
  String id,
  Emotion emotion,
  Intensity intensity,
  QuestionCategory category,
) => GameQuestion(
  id: id,
  text: '¿Quién de los dos...?',
  chapter: Chapter.conexion,
  emotion: emotion,
  intensity: intensity,
  category: category,
  type: QuestionType.comparacion,
  options: const ['Yo', 'Tú'],
);
