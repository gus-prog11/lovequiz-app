import 'dart:math';

import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/intensity.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_question.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_round.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_settings.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/question_filter.dart';
import 'package:LoveQuiz/features/game_engine/domain/repositories/in_memory_question_repository.dart';
import 'package:LoveQuiz/features/game_engine/domain/selectors/question_selector.dart';
import 'package:LoveQuiz/features/game_engine/engine/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameQuestion q({
  required String id,
  Chapter chapter = Chapter.conexion,
  Emotion emotion = Emotion.romance,
  Intensity intensity = Intensity.media,
  QuestionType type = QuestionType.conversacion,
  QuestionCategory category = QuestionCategory.romanticas,
  bool isSpecial = false,
}) => GameQuestion(
  id: id,
  text: 'Texto $id',
  chapter: chapter,
  emotion: emotion,
  intensity: intensity,
  category: category,
  type: type,
  isSpecial: isSpecial,
);

GameRound round({
  Chapter chapter = Chapter.conexion,
  Emotion emotion = Emotion.romance,
  Intensity intensity = Intensity.media,
  List<QuestionType> allowedTypes = const [QuestionType.conversacion],
  QuestionCategory? category = QuestionCategory.romanticas,
  bool isSpecial = false,
}) => GameRound(
  chapter: chapter,
  emotion: emotion,
  intensity: intensity,
  category: category,
  allowedTypes: allowedTypes,
  isSpecial: isSpecial,
);

void main() {
  group('DefaultQuestionSelector', () {
    test('1. encuentra una coincidencia exacta', () async {
      final question = q(id: 'exacta');
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([question]),
      );

      final result = await selector.select(round: round(), usedQuestionIds: {});

      expect(result?.id, 'exacta');
    });

    test('2. permite intensidad cercana cuando no hay coincidencia exacta',
        () async {
      // El espacio pide alta, pero solo existe media: ±1 nivel es aceptable.
      final question = q(id: 'cercana', intensity: Intensity.media);
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([question]),
      );

      final result = await selector.select(
        round: round(intensity: Intensity.alta),
        usedQuestionIds: {},
      );

      expect(result?.id, 'cercana');
    });

    test('3. no repite una pregunta ya utilizada', () async {
      final a = q(id: 'a');
      final b = q(id: 'b');
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([a, b]),
        random: Random(1),
      );

      final first = await selector.select(round: round(), usedQuestionIds: {});
      final second = await selector.select(
        round: round(),
        usedQuestionIds: {first!.id},
      );

      expect(second!.id, isNot(first.id));
    });

    test('4. respeta la emoción solicitada', () async {
      // Otra emoción coincide en todo lo demás, pero la emoción es sagrada.
      final wrongEmotion = q(
        id: 'otra-emocion',
        emotion: Emotion.nostalgia,
      );
      final rightEmotion = q(
        id: 'emocion-correcta',
        emotion: Emotion.romance,
        intensity: Intensity.suave,
        category: QuestionCategory.generales,
      );
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([wrongEmotion, rightEmotion]),
      );

      final result = await selector.select(round: round(), usedQuestionIds: {});

      expect(result?.id, 'emocion-correcta');
      expect(result?.emotion, Emotion.romance);
    });

    test('5. respeta el tipo de pregunta cuando existen alternativas', () async {
      final reto = q(id: 'reto', type: QuestionType.reto);
      final conversacion = q(id: 'conversacion', type: QuestionType.conversacion);
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([reto, conversacion]),
      );

      final result = await selector.select(
        round: round(allowedTypes: const [QuestionType.reto]),
        usedQuestionIds: {},
      );

      expect(result?.id, 'reto');
    });

    test('6. usa fallback (variación de categoría) cuando faltan candidatas',
        () async {
      // El espacio prefiere romanticas, pero solo existe una generales.
      final fallback = q(
        id: 'fallback',
        category: QuestionCategory.generales,
      );
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([fallback]),
      );

      final result = await selector.select(round: round(), usedQuestionIds: {});

      expect(result?.id, 'fallback');
    });

    test('7. devuelve null cuando no existe pregunta compatible', () async {
      // Hay preguntas en el pool, pero ninguna con la emoción pedida.
      final otherEmotion = q(id: 'otra', emotion: Emotion.nostalgia);
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([otherEmotion]),
      );

      final result = await selector.select(
        round: round(emotion: Emotion.coqueteo),
        usedQuestionIds: {},
      );

      expect(result, isNull);
    });

    test('7b. devuelve null cuando el pool del capítulo está vacío', () async {
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository(const []),
      );

      final result = await selector.select(round: round(), usedQuestionIds: {});

      expect(result, isNull);
    });

    test('8. es determinista con la misma semilla', () async {
      final a = q(id: 'a');
      final b = q(id: 'b');
      final questions = [a, b];

      final selectorA = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository(questions),
        random: Random(7),
      );
      final selectorB = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository(questions),
        random: Random(7),
      );

      final first = await selectorA.select(round: round(), usedQuestionIds: {});
      final second = await selectorB.select(round: round(), usedQuestionIds: {});

      expect(first!.id, second!.id);
    });

    test('el pool de un espacio especial solo contiene momentos especiales',
        () async {
      final especial = q(
        id: 'especial',
        isSpecial: true,
        chapter: Chapter.momentoEspecial,
        type: QuestionType.voz,
      );
      final normal = q(
        id: 'normal',
        chapter: Chapter.momentoEspecial,
        type: QuestionType.voz,
      );
      final selector = DefaultQuestionSelector(
        repository: InMemoryQuestionRepository([especial, normal]),
      );

      final result = await selector.select(
        round: round(
          chapter: Chapter.momentoEspecial,
          isSpecial: true,
          allowedTypes: const [QuestionType.voz],
        ),
        usedQuestionIds: {},
      );

      expect(result?.id, 'especial');
    });
  });

  group('InMemoryQuestionRepository', () {
    final questions = [
      q(
        id: 'romance-alta-reto-romanticas',
        intensity: Intensity.alta,
        type: QuestionType.reto,
      ),
      q(id: 'romance-media-conversacion-romanticas'),
      q(
        id: 'nostalgia-media-conversacion-romanticas',
        emotion: Emotion.nostalgia,
      ),
      q(
        id: 'romance-alta-reto-generales',
        category: QuestionCategory.generales,
        intensity: Intensity.alta,
        type: QuestionType.reto,
      ),
    ];
    final repository = InMemoryQuestionRepository(questions);

    test('filtra por combinaciones de criterios', () async {
      final result = await repository.getQuestions(
        const QuestionFilter(
          emotion: Emotion.romance,
          intensity: Intensity.alta,
          type: QuestionType.reto,
          category: QuestionCategory.romanticas,
        ),
      );

      expect(result.map((e) => e.id), ['romance-alta-reto-romanticas']);
    });

    test('filtra por rango de intensidad', () async {
      final result = await repository.getQuestions(
        const QuestionFilter(
          emotion: Emotion.romance,
          minIntensity: Intensity.alta,
        ),
      );

      expect(
        result.map((e) => e.id),
        containsAll(['romance-alta-reto-romanticas', 'romance-alta-reto-generales']),
      );
    });

    test('getQuestionsForRound devuelve el pool por capítulo y isSpecial',
        () async {
      final result = await repository.getQuestionsForRound(
        round(),
      );

      expect(result, hasLength(4));
      expect(result.every((e) => e.isSpecial == false), isTrue);
    });
  });

  group('GameEngine integración', () {
    test('next() asigna al espacio la pregunta del selector', () async {
      // La primera ronda del recorrido es Bienvenida, así que el pool debe
      // tener preguntas de ese capítulo con sus emociones posibles.
      final diversion = q(
        id: 'bienv-diversion',
        chapter: Chapter.bienvenida,
        emotion: Emotion.diversion,
        intensity: Intensity.suave,
        category: QuestionCategory.generales,
      );
      final descubrimiento = q(
        id: 'bienv-descubrimiento',
        chapter: Chapter.bienvenida,
        emotion: Emotion.descubrimiento,
        intensity: Intensity.suave,
        category: QuestionCategory.generales,
      );
      final engine = GameEngine(
        settings: const GameSettings(chapters: Chapter.values),
        repository: InMemoryQuestionRepository([diversion, descubrimiento]),
        random: Random(1),
      );

      await engine.start();
      final selected = await engine.next();

      expect(
        selected?.id,
        anyOf('bienv-diversion', 'bienv-descubrimiento'),
      );
      expect(engine.state.rounds.first.question?.id, selected!.id);
      expect(selected.emotion, engine.state.rounds.first.emotion);
    });

    test('answer() marca la partida como terminada en el último espacio',
        () async {
      final engine = GameEngine(
        settings: const GameSettings(
          chapters: [Chapter.bienvenida],
        ),
        repository: InMemoryQuestionRepository(const []),
      );

      await engine.start();
      expect(engine.state.totalRounds, 5);
      expect(engine.state.finished, isFalse);

      final rounds = engine.state.rounds;
      for (var i = 0; i < 4; i++) {
        await engine.answer(rounds[i].copyWith(skipped: true));
        expect(engine.state.finished, isFalse);
      }

      await engine.answer(rounds[4].copyWith(skipped: true));
      expect(engine.state.finished, isTrue);
    });
  });
}
