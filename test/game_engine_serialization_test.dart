import 'dart:math';

import 'package:LoveQuiz/features/game_engine/data/engine_match_codec.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/intensity.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/migration.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_question.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_round.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pregunta con todos los campos poblados (para el round-trip).
GameQuestion buildQuestion({
  String id = 'nue-test-1',
  String text = '¿Prefieres viajar o quedarte en casa?',
  Chapter chapter = Chapter.conexion,
  Emotion emotion = Emotion.romance,
  Intensity intensity = Intensity.alta,
  QuestionType type = QuestionType.comparacion,
  QuestionCategory category = QuestionCategory.romanticas,
  List<String> options = const ['Viajar', 'Quedarme'],
  bool isSpecial = true,
  QuestionSource source = QuestionSource.original,
  QuestionStatus status = QuestionStatus.listo,
}) =>
    GameQuestion(
      id: id,
      text: text,
      chapter: chapter,
      emotion: emotion,
      intensity: intensity,
      type: type,
      category: category,
      options: options,
      isSpecial: isSpecial,
      source: source,
      status: status,
    );

/// Espacio con todos los campos poblados (para el round-trip).
GameRound buildRound({
  Chapter chapter = Chapter.conexion,
  Emotion emotion = Emotion.romance,
  Intensity intensity = Intensity.alta,
  QuestionCategory? category = QuestionCategory.romanticas,
  bool enforceCategory = true,
  List<QuestionType> allowedTypes = const [
    QuestionType.conversacion,
    QuestionType.reto,
    QuestionType.comparacion,
  ],
  bool isSpecial = false,
  GameQuestion? question,
  bool answered = true,
  bool skipped = false,
  DateTime? startedAt,
}) =>
    GameRound(
      chapter: chapter,
      emotion: emotion,
      intensity: intensity,
      category: category,
      enforceCategory: enforceCategory,
      allowedTypes: allowedTypes,
      isSpecial: isSpecial,
      question: question,
      answered: answered,
      skipped: skipped,
      startedAt: startedAt,
    );

/// Verifica campo a campo que `actual` es equivalente a `expected`.
void expectQuestionEquals(
  GameQuestion actual,
  GameQuestion expected, {
  String? reason,
}) {
  expect(actual.id, expected.id, reason: reason);
  expect(actual.text, expected.text, reason: reason);
  expect(actual.chapter, expected.chapter, reason: reason);
  expect(actual.emotion, expected.emotion, reason: reason);
  expect(actual.intensity, expected.intensity, reason: reason);
  expect(actual.type, expected.type, reason: reason);
  expect(actual.category, expected.category, reason: reason);
  expect(actual.options, expected.options, reason: reason);
  expect(actual.isSpecial, expected.isSpecial, reason: reason);
  expect(actual.source, expected.source, reason: reason);
  expect(actual.status, expected.status, reason: reason);
}

/// Verifica campo a campo que `actual` es equivalente a `expected`.
void expectRoundEquals(
  GameRound actual,
  GameRound expected, {
  String? reason,
}) {
  expect(actual.chapter, expected.chapter, reason: reason);
  expect(actual.emotion, expected.emotion, reason: reason);
  expect(actual.intensity, expected.intensity, reason: reason);
  expect(actual.category, expected.category, reason: reason);
  expect(actual.enforceCategory, expected.enforceCategory, reason: reason);
  expect(actual.allowedTypes, expected.allowedTypes, reason: reason);
  expect(actual.isSpecial, expected.isSpecial, reason: reason);
  expect(actual.answered, expected.answered, reason: reason);
  expect(actual.skipped, expected.skipped, reason: reason);
  expect(actual.startedAt, expected.startedAt, reason: reason);
  if (expected.question == null) {
    expect(actual.question, isNull, reason: reason);
  } else {
    expect(actual.question, isNotNull, reason: reason);
    expectQuestionEquals(
      actual.question!,
      expected.question!,
      reason: reason,
    );
  }
}

void main() {
  group('GameQuestion → Map → GameQuestion (round-trip)', () {
    test('conserva todos los campos y usa la representación estable', () {
      final original = buildQuestion();
      final restored = GameQuestion.fromMap(original.toMap());

      expectQuestionEquals(restored, original);

      // La representación del mapa es explícita (name del enum), nunca el
      // índice numérico ni el label legible.
      expect(original.toMap(), {
        'id': 'nue-test-1',
        'text': '¿Prefieres viajar o quedarte en casa?',
        'chapter': 'conexion',
        'emotion': 'romance',
        'intensity': 'alta',
        'type': 'comparacion',
        'category': 'romanticas',
        'options': ['Viajar', 'Quedarme'],
        'isSpecial': true,
        'source': 'original',
        'status': 'listo',
      });
    });

    test('round-trip con cada capítulo', () {
      for (final chapter in Chapter.values) {
        expectQuestionEquals(
          GameQuestion.fromMap(buildQuestion(chapter: chapter).toMap()),
          buildQuestion(chapter: chapter),
        );
      }
    });

    test('round-trip con cada emoción', () {
      for (final emotion in Emotion.values) {
        expectQuestionEquals(
          GameQuestion.fromMap(buildQuestion(emotion: emotion).toMap()),
          buildQuestion(emotion: emotion),
        );
      }
    });

    test('round-trip con cada intensidad', () {
      for (final intensity in Intensity.values) {
        expectQuestionEquals(
          GameQuestion.fromMap(buildQuestion(intensity: intensity).toMap()),
          buildQuestion(intensity: intensity),
        );
      }
    });

    test('round-trip con cada tipo de pregunta', () {
      for (final type in QuestionType.values) {
        expectQuestionEquals(
          GameQuestion.fromMap(buildQuestion(type: type).toMap()),
          buildQuestion(type: type),
        );
      }
    });

    test('round-trip con cada categoría', () {
      for (final category in QuestionCategory.values) {
        expectQuestionEquals(
          GameQuestion.fromMap(buildQuestion(category: category).toMap()),
          buildQuestion(category: category),
        );
      }
    });

    test('round-trip con cada origen y estado de migración', () {
      for (final source in QuestionSource.values) {
        for (final status in QuestionStatus.values) {
          expectQuestionEquals(
            GameQuestion.fromMap(
              buildQuestion(source: source, status: status).toMap(),
            ),
            buildQuestion(source: source, status: status),
          );
        }
      }
    });

    test('round-trip conserva options vacías y con varias opciones', () {
      expectQuestionEquals(
        GameQuestion.fromMap(buildQuestion(options: const []).toMap()),
        buildQuestion(options: const []),
      );
      expectQuestionEquals(
        GameQuestion.fromMap(
          buildQuestion(options: const ['A', 'B', 'C']).toMap(),
        ),
        buildQuestion(options: const ['A', 'B', 'C']),
      );
    });
  });

  group('GameRound → Map → GameRound (round-trip)', () {
    test('conserva todos los campos (pregunta asignada y timestamps)', () {
      final original = buildRound(
        question: buildQuestion(),
        startedAt: DateTime(2026, 8, 11, 20, 30, 15, 250),
      );
      final restored = GameRound.fromMap(original.toMap());

      expectRoundEquals(restored, original);

      expect(original.toMap(), {
        'chapter': 'conexion',
        'emotion': 'romance',
        'intensity': 'alta',
        'category': 'romanticas',
        'enforceCategory': true,
        'allowedTypes': ['conversacion', 'reto', 'comparacion'],
        'isSpecial': false,
        'question': original.question!.toMap(),
        'answered': true,
        'skipped': false,
        'startedAt': '2026-08-11T20:30:15.250',
      });
    });

    test('conserva pregunta nula y category nula', () {
      final original = buildRound(
        category: null,
        question: null,
        answered: false,
        skipped: false,
      );
      final restored = GameRound.fromMap(original.toMap());

      expect(restored.category, isNull);
      expect(restored.question, isNull);
      expectRoundEquals(restored, original);
    });

    test('conserva allowedTypes como lista de enums', () {
      final original = buildRound(
        allowedTypes: QuestionType.values,
        isSpecial: true,
        question: buildQuestion(
          type: QuestionType.voz,
          chapter: Chapter.momentoEspecial,
          isSpecial: true,
        ),
      );
      final restored = GameRound.fromMap(original.toMap());

      expect(restored.allowedTypes, QuestionType.values);
      expectRoundEquals(restored, original);
    });

    test('conserva startedAt en UTC', () {
      final original = buildRound(
        startedAt: DateTime.utc(2026, 8, 11, 20, 30, 15, 250),
      );
      final restored = GameRound.fromMap(original.toMap());

      expect(restored.startedAt, isNotNull);
      expect(restored.startedAt!.isUtc, isTrue);
      expectRoundEquals(restored, original);
    });
  });

  group('Partida completa del motor (puente online)', () {
    test(
      'GameEngine → 25 rondas → mapa → sala → mapa → rondas equivalentes',
      () async {
        final rounds = await buildEngineMatch(random: Random(42));
        expect(rounds, hasLength(25));
        expect(
          rounds.every((r) => r.question != null),
          isTrue,
          reason: 'con el banco V1 completo no debería haber huecos',
        );

        // Puente: el host codifica el recorrido y lo guarda en la sala. La
        // sala conserva intacto el flujo legacy (questions/currentQuestion/
        // turn): `engineRounds` es un campo adicional.
        final encoded = encodeEngineMatch(rounds);
        final sala = <String, dynamic>{
          'engineRounds': encoded,
          'questions': <Map<String, dynamic>>[],
          'currentQuestion': 0,
          'turn': 0,
          'status': 'playing',
        };

        // El invitado lee `engineRounds` desde el snapshot de la sala y
        // reconstruye el recorrido.
        final restored = decodeEngineMatch(sala['engineRounds'] as List);

        expect(restored, hasLength(25));
        for (var i = 0; i < rounds.length; i++) {
          expectRoundEquals(restored[i], rounds[i], reason: 'ronda $i');
        }

        // El recorrido reconstruido es idéntico mapa a mapa al original.
        expect(
          restored.map((r) => r.toMap()).toList(),
          rounds.map((r) => r.toMap()).toList(),
        );
      },
    );
  });
}
