import 'dart:math';

import 'package:LoveQuiz/features/game_engine/domain/builders/match_builder.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/intensity.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_question.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_round.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_settings.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/question_filter.dart';
import 'package:LoveQuiz/features/game_engine/domain/repositories/question_repository.dart';
import 'package:LoveQuiz/features/game_engine/engine/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

MatchBuilder defaultBuilder([int seed = 42]) => MatchBuilder(
  chapters: Chapter.values.map(GameChapter.forChapter).toList(),
  random: Random(seed),
);

void main() {
  group('MatchBuilder', () {
    test('construye el recorrido completo de 25 espacios en orden', () {
      final rounds = defaultBuilder().build();

      expect(rounds, hasLength(25));
      expect(rounds.map((r) => r.chapter).toList(), [
        Chapter.bienvenida, Chapter.bienvenida, Chapter.bienvenida,
        Chapter.bienvenida, Chapter.bienvenida,
        Chapter.calentamiento, Chapter.calentamiento,
        Chapter.calentamiento, Chapter.calentamiento,
        Chapter.calentamiento, Chapter.calentamiento,
        Chapter.conexion, Chapter.conexion, Chapter.conexion,
        Chapter.conexion, Chapter.conexion, Chapter.conexion,
        Chapter.conexion, Chapter.conexion,
        Chapter.momentoEspecial,
        Chapter.cierre, Chapter.cierre, Chapter.cierre,
        Chapter.cierre, Chapter.cierre,
      ]);
    });

    test('cada emoción pertenece al pool de su capítulo', () {
      final rounds = defaultBuilder().build();
      for (final round in rounds) {
        final chapter = GameChapter.forChapter(round.chapter);
        expect(chapter.emotions, contains(round.emotion),
            reason: '${round.chapter} admite ${round.emotion.label}');
      }
    });

    group('preferencia temática', () {
      test('sin preferencias, todas las categorías participan', () {
        final rounds = defaultBuilder().build();
        final categories = rounds.map((r) => r.category).toSet();
        expect(categories.length, greaterThan(1),
            reason: 'con todas las categorías debería haber variedad');
      });

      test('con preferencias, la categoría del espacio sale de las elegidas',
          () {
        const preferred = [
          QuestionCategory.romanticas,
          QuestionCategory.divertidas,
        ];
        final rounds = MatchBuilder(
          chapters: Chapter.values.map(GameChapter.forChapter).toList(),
          preferredCategories: preferred,
          random: Random(7),
        ).build();

        for (final round in rounds) {
          expect(preferred, contains(round.category),
              reason: '${round.category} no está en la preferencia');
        }
      });

      test('las preferencias no rompen la emoción del espacio', () {
        final rounds = MatchBuilder(
          chapters: Chapter.values.map(GameChapter.forChapter).toList(),
          preferredCategories: const [QuestionCategory.retos],
          random: Random(3),
        ).build();
        for (final round in rounds) {
          final chapter = GameChapter.forChapter(round.chapter);
          expect(chapter.emotions, contains(round.emotion));
        }
      });
    });

    test('no repite la misma emoción en dos espacios consecutivos', () {
      final rounds = defaultBuilder().build();
      for (var i = 1; i < rounds.length; i++) {
        expect(rounds[i].emotion, isNot(rounds[i - 1].emotion),
            reason: 'espacio $i repite emoción ${rounds[i].emotion.label}');
      }
    });

    test('prefiere transiciones suaves cuando el pool tiene opción', () {
      final rounds = defaultBuilder().build();
      for (var i = 1; i < rounds.length; i++) {
        final prev = rounds[i - 1].emotion;
        final chapter = GameChapter.forChapter(rounds[i].chapter);
        // ¿El capítulo tiene alguna emoción que siga suavemente a la anterior?
        final hasSmoothOption = chapter.emotions
            .where((e) =>
                e != prev && smoothTransitions[prev]!.contains(e))
            .isNotEmpty;
        if (hasSmoothOption) {
          expect(
            smoothTransitions[prev],
            contains(rounds[i].emotion),
            reason:
                'espacio $i saltó a ${rounds[i].emotion.label} desde '
                '${prev.label} aunque había opción suave en '
                '${chapter.id.label}',
          );
        }
      }
    });

    test('la intensidad arranca en el mínimo y no decrece por capítulo', () {
      final rounds = defaultBuilder().build();
      for (final chapter in Chapter.values) {
        final spaces = rounds.where((r) => r.chapter == chapter).toList();
        final config = GameChapter.forChapter(chapter);

        if (spaces.length == 1) {
          // Capítulo de un solo espacio (Momento especial): llega directo a
          // la intensidad objetivo, el pico de la partida.
          expect(spaces.first.intensity, config.targetIntensity);
          continue;
        }
        expect(spaces.first.intensity, config.minIntensity);
        expect(spaces.last.intensity, config.targetIntensity);
        for (var i = 1; i < spaces.length; i++) {
          expect(
            spaces[i].intensity.level >= spaces[i - 1].intensity.level,
            isTrue,
            reason: 'rampa del capítulo $chapter debe ser creciente',
          );
        }
      }
    });

    test('garantiza exactamente un momento especial, con voz', () {
      final rounds = defaultBuilder().build();
      final specials = rounds.where((r) => r.isSpecial).toList();

      expect(specials, hasLength(1));
      final special = specials.single;
      expect(special.chapter, Chapter.momentoEspecial);
      expect(special.allowedTypes, [QuestionType.voz]);
      expect(special.intensity, Intensity.intensa);
    });

    test('el cierre solo usa emociones positivas', () {
      final rounds = defaultBuilder().build();
      const positive = {
        Emotion.romance,
        Emotion.nostalgia,
        Emotion.celebracion,
        Emotion.futuro,
        Emotion.recuerdo,
      };

      for (final round in rounds.where((r) => r.chapter == Chapter.cierre)) {
        expect(positive, contains(round.emotion));
      }
    });

    test('el cierre no repite emoción dentro del capítulo', () {
      // 5 emociones para 5 espacios: cada una aparece exactamente una vez, con
      // lo que ninguna domina el cierre (ni nostalgia 3/5).
      for (final seed in [1, 7, 42, 99, 200, 777, 2024]) {
        final rounds = defaultBuilder(seed).build();
        final cierre = rounds.where((r) => r.chapter == Chapter.cierre).toList();
        final emotions = cierre.map((r) => r.emotion).toList();
        final chapter = GameChapter.forChapter(Chapter.cierre);

        expect(emotions, hasLength(5), reason: 'seed $seed');
        expect(emotions.toSet(), chapter.emotions.toSet(),
            reason: 'seed $seed: el cierre debe cubrir las 5 emociones');
      }
    });

    test('es determinista con un Random sembrado', () {
      final first = defaultBuilder().build();
      final second = defaultBuilder().build();

      expect(second, hasLength(first.length));
      for (var i = 0; i < first.length; i++) {
        expect(second[i].emotion, first[i].emotion);
        expect(second[i].intensity, first[i].intensity);
        expect(second[i].category, first[i].category);
        expect(second[i].isSpecial, first[i].isSpecial);
      }
    });
  });

  group('GameEngine', () {
    test('start() construye la partida completa antes de asignar preguntas',
        () async {
      final engine = GameEngine(
        settings: const GameSettings(chapters: Chapter.values),
        repository: _FakeQuestionRepository(),
        random: Random(7),
      );

      await engine.start();

      final state = engine.state;
      expect(state.rounds, hasLength(25));
      expect(state.totalRounds, 25);
      expect(state.roundIndex, 0);
      expect(state.currentChapter, Chapter.bienvenida);
      expect(state.finished, isFalse);
      // Ningún espacio tiene pregunta aún: la asignación es un paso posterior.
      expect(state.rounds.every((r) => r.question == null), isTrue);
      expect(state.history, isEmpty);
    });

    test('start() respeta capítulos configurados fuera del orden por defecto',
        () async {
      final engine = GameEngine(
        settings: const GameSettings(
          chapters: [Chapter.bienvenida, Chapter.cierre],
        ),
        repository: _FakeQuestionRepository(),
        random: Random(3),
      );

      await engine.start();

      expect(engine.state.rounds, hasLength(10));
      expect(
        engine.state.rounds.map((r) => r.chapter).toSet(),
        {Chapter.bienvenida, Chapter.cierre},
      );
    });
  });
}

class _FakeQuestionRepository implements QuestionRepository {
  @override
  Future<List<GameQuestion>> getQuestions(QuestionFilter filter) async {
    return const [];
  }

  @override
  Future<List<GameQuestion>> getQuestionsForRound(GameRound round) async {
    return const [];
  }
}
