import 'dart:math';

import 'package:LoveQuiz/features/game_engine/domain/builders/match_builder.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/intensity.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_round.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('modos de juego', () {
    test('MatchBuilder: sin preferencias la categoría es blanda', () {
      final rounds = MatchBuilder(
        chapters: Chapter.values.map(GameChapter.forChapter).toList(),
        random: Random(42),
      ).build();
      expect(rounds.every((r) => !r.enforceCategory), isTrue,
          reason: 'modo aleatorio: ninguna categoría es fuerte');
    });

    test('MatchBuilder: con preferencias el tema es fuerte', () {
      final rounds = MatchBuilder(
        chapters: Chapter.values.map(GameChapter.forChapter).toList(),
        preferredCategories: const [QuestionCategory.romanticas],
        random: Random(7),
      ).build();
      expect(rounds.every((r) => r.enforceCategory), isTrue,
          reason: 'modo temático: el tema debe ser restricción fuerte');
      expect(
        rounds.every((r) => r.category == QuestionCategory.romanticas),
        isTrue,
        reason: 'el espacio siempre prefiere la categoría elegida',
      );
    });

    test('modo temático romanticas: el tema domina el recorrido', () async {
      final rounds = await buildEngineMatch(
        preferredCategories: const [QuestionCategory.romanticas],
        random: Random(7),
      );
      expect(rounds.length, greaterThanOrEqualTo(23),
          reason: 'el recorrido no debe romperse');

      final themed = rounds
          .where((r) => r.question!.category == QuestionCategory.romanticas)
          .length;
      // El banco romántico solo tiene 1 pregunta en Bienvenida, así que ese
      // capítulo cae a generales. El resto del recorrido debe ser del tema.
      expect(themed, greaterThanOrEqualTo(20),
          reason: 'el tema debe dominar (~84% con el banco actual)');
    });

    test('modo temático romanticas: el desenlace es de voz del tema', () async {
      final rounds = await buildEngineMatch(
        preferredCategories: const [QuestionCategory.romanticas],
        random: Random(3),
      );
      final climax = rounds.where((r) => r.chapter == Chapter.momentoEspecial);
      expect(climax, isNotEmpty, reason: 'debe existir el Momento especial');
      for (final round in climax) {
        expect(round.question!.type, QuestionType.voz);
        expect(round.question!.category, QuestionCategory.romanticas,
            reason: 'el desenlace debe ser del tema elegido');
      }
    });

    test('modo temático retos: la partida se juega completa', () async {
      final rounds = await buildEngineMatch(
        preferredCategories: const [QuestionCategory.retos],
        random: Random(5),
      );
      expect(rounds.length, greaterThanOrEqualTo(23));
      expect(rounds.every((r) => r.question != null), isTrue);
    });

    test('modo aleatorio: mezcla categorías', () async {
      final categories = <QuestionCategory>{};
      for (var seed = 1; seed <= 5; seed++) {
        final rounds = await buildEngineMatch(random: Random(seed));
        for (final round in rounds) {
          categories.add(round.question!.category);
        }
      }
      expect(categories.length, greaterThanOrEqualTo(3),
          reason: 'el modo aleatorio debe mezclar varios temas');
    });

    test('pickNoVoiceFallback devuelve una pregunta escrita', () async {
      final round = GameRound(
        chapter: Chapter.momentoEspecial,
        emotion: Emotion.romance,
        intensity: Intensity.intensa,
        category: QuestionCategory.romanticas,
        allowedTypes: const [QuestionType.voz],
        isSpecial: true,
      );
      final fallback = await pickNoVoiceFallback(
        round: round,
        preferredCategories: const [QuestionCategory.romanticas],
        random: Random(1),
      );
      expect(fallback, isNotNull);
      expect(fallback!.type, isNot(QuestionType.voz),
          reason: 'el fallback nunca es de voz');
      expect(fallback.category, QuestionCategory.romanticas,
          reason: 'el fallback debe respetar el tema');
    });

    test('pickNoVoiceFallback sin tema devuelve algo jugable', () async {
      final round = GameRound(
        chapter: Chapter.momentoEspecial,
        emotion: Emotion.recuerdo,
        intensity: Intensity.intensa,
        category: QuestionCategory.romanticas,
        allowedTypes: const [QuestionType.voz],
        isSpecial: true,
      );
      final fallback = await pickNoVoiceFallback(round: round);
      expect(fallback, isNotNull);
      expect(fallback!.type, isNot(QuestionType.voz));
    });
  });

  group('duración de la partida', () {
    List<GameChapter> baseChapters() =>
        Chapter.values.map(GameChapter.forChapter).toList();

    test('escala capítulos a 10 rondas conservando el arco', () {
      final scaled = scaleChaptersForRounds(baseChapters(), 10);
      expect(
        scaled.fold<int>(0, (sum, c) => sum + c.approximateQuestionCount),
        10,
      );
      expect(scaled.first.id, Chapter.bienvenida);
      expect(scaled.last.id, Chapter.cierre);
      expect(
        scaled
            .where((c) => c.allowsSpecialMoments)
            .every((c) => c.approximateQuestionCount == 1),
        isTrue,
        reason: 'el Momento especial sigue siendo el pico (1 espacio)',
      );
    });

    test('escala capítulos a 20 rondas conservando el arco', () {
      final scaled = scaleChaptersForRounds(baseChapters(), 20);
      expect(
        scaled.fold<int>(0, (sum, c) => sum + c.approximateQuestionCount),
        20,
      );
      expect(scaled.first.id, Chapter.bienvenida);
      expect(scaled.last.id, Chapter.cierre);
    });

    test('con 25 (o más) devuelve el recorrido base intacto', () {
      final base = baseChapters();
      expect(scaleChaptersForRounds(base, 25), same(base));
      expect(scaleChaptersForRounds(base, 30), same(base));
    });

    test('partida corta de 10: exactamente 10 rondas jugables', () async {
      final rounds = await buildEngineMatch(
        totalRounds: 10,
        random: Random(2),
      );
      expect(rounds, hasLength(10));
      expect(rounds.every((r) => r.question != null), isTrue);
      expect(rounds.first.chapter, Chapter.bienvenida);
      expect(rounds.last.chapter, Chapter.cierre);
      expect(
        rounds.any((r) => r.chapter == Chapter.momentoEspecial),
        isTrue,
        reason: 'la partida corta mantiene el Momento especial',
      );
    });

    test('partida de 20: exactamente 20 rondas jugables', () async {
      final rounds = await buildEngineMatch(
        totalRounds: 20,
        random: Random(6),
      );
      expect(rounds, hasLength(20));
      expect(rounds.every((r) => r.question != null), isTrue);
      expect(rounds.first.chapter, Chapter.bienvenida);
      expect(rounds.last.chapter, Chapter.cierre);
    });

    test('partida completa: 25 rondas (comportamiento por defecto)', () async {
      final rounds = await buildEngineMatch(random: Random(8));
      expect(rounds, hasLength(25));
    });
  });
}
