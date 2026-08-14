import 'dart:math';

import 'package:LoveQuiz/features/game_engine/data/comodin_questions_v1.dart';
import 'package:LoveQuiz/features/game_engine/data/migrated_questions.dart';
import 'package:LoveQuiz/features/game_engine/data/new_questions_v1.dart';
import 'package:LoveQuiz/features/game_engine/data/question_bank_v1.dart';
import 'package:LoveQuiz/features/game_engine/data/thematic_questions_v1.dart';
import 'package:LoveQuiz/features/game_engine/domain/builders/match_builder.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/intensity.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/migration.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_category.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/question_filter.dart';
import 'package:LoveQuiz/features/game_engine/domain/repositories/in_memory_question_repository.dart';
import 'package:LoveQuiz/features/game_engine/domain/selectors/question_selector.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

const _seedsToSimulate = 40;

MatchBuilder _builder(int seed) => MatchBuilder(
  chapters: Chapter.values.map(GameChapter.forChapter).toList(),
  random: Random(seed),
);

DefaultQuestionSelector _selector(int seed) => DefaultQuestionSelector(
  repository: InMemoryQuestionRepository(bancoV1Questions),
  random: Random(seed),
);

void main() {
  group('Banco V1 — estructura', () {
    test('el banco legacy se clasifica completo sin pérdidas', () {
      expect(migratedQuestions, hasLength(356));
      expect(newQuestionsV1, hasLength(18));
      expect(thematicQuestionsV1, hasLength(614));
      expect(comodinQuestionsV1, hasLength(42));
      // 289 legacy listo + 18 huecos + 28 voces temáticas + 614 temáticas +
      // 42 comodines de conexión + 188 comparaciones nuevas.
      expect(bancoV1Questions, hasLength(1161));
      expect(migradasPendientesV1, hasLength(85));
    });

    test('los ids son únicos en todo el banco', () {
      final ids = bancoV1Questions.map((q) => q.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('el prefijo del id es coherente con el origen', () {
      for (final q in bancoV1Questions) {
        if (q.id.startsWith('leg-')) {
          expect(q.source, QuestionSource.legacy);
        } else {
          expect(q.id, startsWith('nue-'));
          expect(q.source, QuestionSource.original);
        }
      }
    });

    test('el banco jugable solo contiene preguntas listo', () {
      for (final q in bancoV1Questions) {
        expect(q.status, QuestionStatus.listo, reason: q.id);
      }
    });

    test('toda pregunta con texto es válida (no vacío, sin espacios raros)',
        () {
      for (final q in bancoV1Questions) {
        expect(q.text.trim(), isNotEmpty, reason: q.id);
        expect(q.text.trim().length, greaterThan(10), reason: q.id);
      }
    });

    test('no hay texto duplicado en la misma celda', () {
      final seen = <String, Set<String>>{};
      for (final q in bancoV1Questions) {
        final key = '${q.chapter}|${q.emotion}|${q.intensity}|${q.type}';
        final texts = seen.putIfAbsent(key, () => {});
        expect(texts.add(q.text), isTrue,
            reason: 'texto duplicado en $key: "${q.text}"');
      }
    });
  });

  group('Banco V1 — coherencia con el motor', () {
    test('la emoción está en el pool del capítulo', () {
      for (final q in bancoV1Questions) {
        final config = GameChapter.forChapter(q.chapter);
        expect(config.emotions, contains(q.emotion),
            reason: '${q.id}: ${q.chapter} no admite ${q.emotion}');
      }
    });

    test('la intensidad está dentro de la rampa del capítulo', () {
      for (final q in bancoV1Questions) {
        final config = GameChapter.forChapter(q.chapter);
        expect(q.intensity.level, greaterThanOrEqualTo(config.minIntensity.level),
            reason: '${q.id}: intensidad por debajo del mínimo de ${q.chapter}');
        expect(q.intensity.level, lessThanOrEqualTo(config.maxIntensity.level),
            reason: '${q.id}: intensidad por encima del máximo de ${q.chapter}');
      }
    });

    test('el tipo está permitido en el capítulo', () {
      for (final q in bancoV1Questions) {
        final config = GameChapter.forChapter(q.chapter);
        expect(config.allowedTypes, contains(q.type),
            reason: '${q.id}: tipo ${q.type} no permitido en ${q.chapter}');
      }
    });

    test('las preguntas de voz son especiales y solo viven en el Momento '
        'Especial', () {
      final voz = bancoV1Questions.where((q) => q.type == QuestionType.voz);
      // 10 legadas + 28 temáticas (desenlace de voz por categoría).
      expect(voz, hasLength(38));
      for (final q in voz) {
        expect(q.isSpecial, isTrue, reason: q.id);
        expect(q.chapter, Chapter.momentoEspecial, reason: q.id);
        expect(q.intensity, Intensity.intensa, reason: q.id);
      }
      // El resto no se marca especial: la escasez del momento es única.
      for (final q in bancoV1Questions.where((q) => q.type != QuestionType.voz)) {
        expect(q.isSpecial, isFalse, reason: q.id);
      }
    });

    test('los retos de acción usan QuestionType.reto', () {
      // Los momentos de voz temáticos (desenlace) son la excepción: usan voz.
      // En legacy la regla aplica a `locas`/`retos` migradas de acción; en el
      // lote temático, el bloque de `retos` usa `QuestionType.reto` (Bienvenida
      // y Cierre ya lo admiten), mientras las `locas` temáticas son
      // conversacionales.
      final retos = bancoV1Questions.where(
        (q) =>
            q.type != QuestionType.voz &&
            (q.source == QuestionSource.legacy &&
                    (q.category.name == 'locas' || q.category.name == 'retos')
                || q.category == QuestionCategory.retos),
      );
      expect(retos, isNotEmpty);
      for (final q in retos) {
        expect(q.type, QuestionType.reto, reason: q.id);
      }
    });

    test('las comparaciones traen 2 opciones y viven en capítulos que las '
        'permiten', () {
      final comparaciones =
          bancoV1Questions.where((q) => q.type == QuestionType.comparacion);
      // Piloto (18) + banco grande nuevo (188): variedad mecánica completa.
      expect(comparaciones, hasLength(206));
      for (final q in comparaciones) {
        expect(q.options, hasLength(2), reason: q.id);
        expect(q.options.every((o) => o.trim().isNotEmpty), isTrue,
            reason: q.id);
        expect(const [Chapter.conexion, Chapter.cierre], contains(q.chapter),
            reason: q.id);
        expect(q.intensity.level, greaterThanOrEqualTo(Intensity.media.level),
            reason: q.id);
      }
      // El banco grande cubre varias categorías, no solo románticas/calientes.
      expect(
        comparaciones.map((q) => q.category).toSet(),
        containsAll(const [
          QuestionCategory.romanticas,
          QuestionCategory.calientes,
          QuestionCategory.divertidas,
          QuestionCategory.generales,
        ]),
      );
    });

    test('el filtro del repositorio respeta source y status', () async {
      final repo = InMemoryQuestionRepository(bancoV1Questions);

      final onlyLegacy = await repo.getQuestions(
        const QuestionFilter(source: QuestionSource.legacy),
      );
      expect(onlyLegacy, isNotEmpty);
      expect(onlyLegacy.every((q) => q.source == QuestionSource.legacy), isTrue);

      final onlyNue = await repo.getQuestions(
        const QuestionFilter(source: QuestionSource.original),
      );
      // 18 huecos + 614 temáticas + 28 voces temáticas + 42 comodines +
      // 188 comparaciones = 890 originales.
      expect(onlyNue, hasLength(890));

      final onlyReview = await repo.getQuestions(
        const QuestionFilter(status: QuestionStatus.needsReview),
      );
      // needsReview no está en el banco jugable: se obtiene desde migrated.
      expect(onlyReview, isEmpty);
      final repoFull = InMemoryQuestionRepository(migratedQuestions);
      final review = await repoFull.getQuestions(
        const QuestionFilter(status: QuestionStatus.needsReview),
      );
      // El bloque needsReview se resolvió: 66 pasaron a listo y extremas-1 a
      // incompatible, así que ya no queda ninguna en revisión.
      expect(review, isEmpty);
    });
  });

  group('Banco V1 — comodines de conexión', () {
    test('son 42, con id/type/source/status coherentes', () {
      final comodines =
          comodinQuestionsV1.where((q) => q.type == QuestionType.comodin);
      expect(comodines, hasLength(42));
      for (final q in comodines) {
        expect(q.id, startsWith('nue-comodin-conexion-'), reason: q.id);
        expect(q.type, QuestionType.comodin, reason: q.id);
        expect(q.source, QuestionSource.original, reason: q.id);
        expect(q.status, QuestionStatus.listo, reason: q.id);
        expect(q.isSpecial, isFalse, reason: q.id);
        expect(q.chapter, Chapter.conexion, reason: q.id);
        expect(q.category, QuestionCategory.generales, reason: q.id);
        expect(q.text.trim(), isNotEmpty, reason: q.id);
        expect(q.text.trim().length, greaterThan(10), reason: q.id);
      }
    });

    test('cubre romance, nostalgia, futuro, coqueteo, celebración, diversión '
        'y conexión con 3 por emoción e intensidad', () {
      const esperadas = {
        Emotion.romance,
        Emotion.nostalgia,
        Emotion.futuro,
        Emotion.coqueteo,
        Emotion.celebracion,
        Emotion.diversion,
        Emotion.conexion,
      };
      final combos = <(Emotion, Intensity)>[
        for (final e in esperadas)
          for (final i in [Intensity.media, Intensity.alta]) (e, i),
      ];
      // 7 emociones x 2 intensidades x 3 textos = 42 comodines.
      for (final combo in combos) {
        final count = comodinQuestionsV1
            .where((q) => q.emotion == combo.$1 && q.intensity == combo.$2)
            .length;
        expect(count, 3, reason: '${combo.$1}/${combo.$2}');
      }
      // Sin textos repetidos entre comodines.
      final texts = comodinQuestionsV1.map((q) => q.text).toSet();
      expect(texts, hasLength(42));
    });
  });

  group('Banco V1 — simulación de 40 partidas', () {
    test('todas las partidas se construyen sin espacios vacíos ni repetidos',
        () async {
      final failures = <String>[];
      for (var seed = 1; seed <= _seedsToSimulate; seed++) {
        final rounds = _builder(seed).build();
        final selector = _selector(seed);
        final used = <String>{};
        for (final round in rounds) {
          final q = await selector.select(round: round, usedQuestionIds: used);
          if (q == null) {
            failures.add(
              'seed $seed: sin pregunta para '
              '${round.chapter.name}/${round.emotion.name}/'
              '${round.intensity.name}',
            );
          } else {
            expect(used.add(q.id), isTrue,
                reason: 'pregunta repetida en la partida $seed');
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('la asignación es determinista con la misma semilla', () async {
      Future<List<String>> play(int seed) async {
        final rounds = _builder(seed).build();
        final selector = _selector(seed);
        final used = <String>{};
        final ids = <String>[];
        for (final round in rounds) {
          final q = await selector.select(round: round, usedQuestionIds: used);
          ids.add(q!.id);
          used.add(q.id);
        }
        return ids;
      }

      expect(await play(7), await play(7));
      expect(await play(7), isNot(await play(8)));
    });

    test('cada partida usa exactamente una pregunta por espacio y sin '
        'colisiones', () async {
      final ids = <String>{};
      for (var seed = 1; seed <= _seedsToSimulate; seed++) {
        final rounds = _builder(seed).build();
        final selector = _selector(seed);
        final used = <String>{};
        for (final round in rounds) {
          final q = await selector.select(round: round, usedQuestionIds: used);
          if (q != null) ids.add(q.id);
        }
      }
      expect(ids.length, greaterThanOrEqualTo(150),
          reason: 'se espera variedad de preguntas entre partidas');
    });
  });

  group('buildEngineMatch — partida jugable con preferencia temática', () {
    test('construye la partida completa sin huecos ni repetidas', () async {
      final rounds = await buildEngineMatch();
      expect(rounds, isNotEmpty);
      expect(rounds.length, greaterThanOrEqualTo(23),
          reason: 'la partida del motor debe ser casi completa (25 espacios)');
      final ids = rounds.map((r) => r.question!.id).toList();
      expect(ids.toSet(), hasLength(ids.length),
          reason: 'no debe repetir preguntas en la misma partida');
      for (final round in rounds) {
        expect(round.question, isNotNull,
            reason: 'buildEngineMatch descarta huecos, no los conserva');
      }
    });

    test('las categorías elegidas se sienten sin romper el recorrido',
        () async {
      final rounds = await buildEngineMatch(
        preferredCategories: const [
          QuestionCategory.romanticas,
          QuestionCategory.divertidas,
        ],
      );

      // El recorrido completo se juega: los 5 capítulos están presentes.
      final chapters = rounds.map((r) => r.chapter).toSet();
      expect(chapters, containsAll(Chapter.values));

      // Sin huecos: toda ronda tiene pregunta.
      expect(rounds.every((r) => r.question != null), isTrue);

      // La preferencia influye: una fracción notable de preguntas es del tema
      // elegido (romanticas/divertidas). No es 100% porque es preferencia
      // blanda, pero debe haber variedad temática evidente.
      final themed = rounds
          .where((r) => const {
                QuestionCategory.romanticas,
                QuestionCategory.divertidas,
              }.contains(r.question!.category))
          .length;
      expect(themed, greaterThanOrEqualTo(2),
          reason: 'la preferencia debe reflejarse en al menos algunas rondas');
    });

    test('con solo retos la partida se juega completa (preferencia blanda)',
        () async {
      // Los retos apenas tienen preguntas: la escalera debe degradar a otras
      // categorías sin romper la partida (las 25 rondas se juegan).
      final rounds = await buildEngineMatch(
        preferredCategories: const [QuestionCategory.retos],
      );
      expect(rounds.length, greaterThanOrEqualTo(23));
      expect(rounds.every((r) => r.question != null), isTrue);
    });

    test('con románticas/calientes aparecen comparaciones y se juegan completas',
        () async {
      var comparacionesVistas = 0;
      for (var seed = 1; seed <= 20; seed++) {
        final rounds = await buildEngineMatch(
          preferredCategories: const [
            QuestionCategory.romanticas,
            QuestionCategory.calientes,
          ],
          random: Random(seed),
        );
        expect(rounds.length, greaterThanOrEqualTo(23));
        for (final round in rounds) {
          final q = round.question!;
          expect(q.type == QuestionType.comparacion
              ? q.options.length == 2 && q.options.every((o) => o.isNotEmpty)
              : true, isTrue,
              reason: 'comparación sin 2 opciones válidas (${q.id})');
          if (q.type == QuestionType.comparacion) {
            comparacionesVistas++;
            // Viven en Conexión o Cierre, los capítulos que las permiten.
            expect(
              const [Chapter.conexion, Chapter.cierre],
              contains(round.chapter),
              reason: q.id,
            );
          }
        }
      }
      // Con 20 semillas y preferencia doble, la variedad mecánica aparece:
      // cada partida de románticas/calientes tiene varios espacios de Conexión
      // donde el bloque de comparaciones compite con el resto de la categoría.
      expect(comparacionesVistas, greaterThan(0),
          reason: 'las comparaciones piloto deben aparecer en la simulación');
    });
  });
}
