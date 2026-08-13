import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:LoveQuiz/features/game_engine/data/experimental_questions.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/emotion.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_settings.dart';
import 'package:LoveQuiz/features/game_engine/domain/repositories/in_memory_question_repository.dart';
import 'package:LoveQuiz/features/game_engine/engine/game_engine.dart';

/// Registra en consola la traza de la partida (se muestra en el reporte de
/// `flutter test`).
void _log(Object message) {
  // ignore: avoid_print
  print(message);
}

/// Crea un motor con una partida completa (25 espacios) sobre el set
/// experimental y una semilla que lo hace reproducible.
GameEngine _newEngine(int seed) => GameEngine(
  settings: const GameSettings(chapters: Chapter.values),
  repository: InMemoryQuestionRepository(experimentalQuestions),
  random: Random(seed),
);

/// Juega toda la partida respondiendo cada ronda. Devuelve cuántas rondas se
/// completaron: 25 = partida completa; menos = el selector se quedó sin
/// pregunta compatible (Nivel 5).
Future<int> _playUntilFinished(GameEngine engine) async {
  var count = 0;
  while (engine.state.canContinue) {
    final question = await engine.next();
    if (question == null) break;
    await engine.answer(engine.state.rounds[engine.state.roundIndex]);
    count++;
  }
  return count;
}

void main() {
  test(
    'recorre una partida completa de 25 rondas con las 66 preguntas experimentales',
    () async {
      // El set experimental no cubre todas las combinaciones emoción ×
      // intensidad × tipo × categoría, así que no toda semilla produce una
      // partida jugable: con algunas el MatchBuilder pide una emoción sin
      // banco y next() vuelve null. Se busca la primera semilla determinista
      // que completa las 25 rondas y se validan los invariantes sobre esa
      // partida.
      int? seed;
      for (var s = 0; s < 500 && seed == null; s++) {
        final engine = _newEngine(s);
        await engine.start();
        if (await _playUntilFinished(engine) == 25) seed = s;
      }
      expect(
        seed,
        isNotNull,
        reason:
            'ninguna semilla (0..499) produjo una partida completable con '
            'las preguntas experimentales',
      );

      final engine = _newEngine(seed!);
      await engine.start();

      // Recorre la partida registrando el detalle de cada ronda.
      final selectedIds = <String>[];
      var roundNumber = 0;
      while (engine.state.canContinue) {
        final question = await engine.next();
        expect(
          question,
          isNotNull,
          reason:
              'la ronda ${engine.state.roundIndex + 1} quedó sin pregunta '
              '(Nivel 5)',
        );

        final round = engine.state.rounds[engine.state.roundIndex];
        _log(
          'Ronda ${(roundNumber + 1).toString().padLeft(2, '0')} | '
          'capítulo: ${round.chapter.label.padRight(16)} | '
          'emoción: ${round.emotion.label.padRight(14)} | '
          'intensidad: ${round.intensity.label.padRight(8)} | '
          'tipo: ${round.question!.type.name.padRight(11)} | '
          'categoría: ${round.category?.label ?? 'sin preferencia'} | '
          'pregunta: ${round.question!.id}',
        );

        selectedIds.add(round.question!.id);
        await engine.answer(round);
        roundNumber++;
      }

      final rounds = engine.state.rounds;

      // 1. Exactamente 25 rondas, todas respondidas.
      expect(rounds, hasLength(25));
      expect(engine.state.totalRounds, 25);
      expect(roundNumber, 25);
      expect(engine.state.history, hasLength(25));

      // 2. Sin preguntas repetidas.
      expect(selectedIds, hasLength(25));
      expect(selectedIds.toSet(), hasLength(25));

      // 3. Orden de capítulos esperado.
      final expectedOrder = <Chapter>[
        Chapter.bienvenida,
        Chapter.bienvenida,
        Chapter.bienvenida,
        Chapter.bienvenida,
        Chapter.bienvenida,
        Chapter.calentamiento,
        Chapter.calentamiento,
        Chapter.calentamiento,
        Chapter.calentamiento,
        Chapter.calentamiento,
        Chapter.calentamiento,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.conexion,
        Chapter.momentoEspecial,
        Chapter.cierre,
        Chapter.cierre,
        Chapter.cierre,
        Chapter.cierre,
        Chapter.cierre,
      ];
      expect(rounds.map((r) => r.chapter).toList(), expectedOrder);

      // 4. Exactamente un momento especial y es una pregunta de voz.
      final specialRounds = rounds.where((r) => r.isSpecial).toList();
      expect(specialRounds, hasLength(1));
      final special = specialRounds.single;
      expect(special.chapter, Chapter.momentoEspecial);
      expect(special.question, isNotNull);
      expect(special.question!.type, QuestionType.voz);
      expect(special.question!.isSpecial, isTrue);

      // 5. El cierre usa emociones permitidas (positivas).
      const allowedClosing = {
        Emotion.romance,
        Emotion.nostalgia,
        Emotion.celebracion,
        Emotion.futuro,
        Emotion.recuerdo,
      };
      for (final r in rounds.where((r) => r.chapter == Chapter.cierre)) {
        expect(
          allowedClosing,
          contains(r.emotion),
          reason: 'el cierre no debería usar la emoción ${r.emotion.label}',
        );
      }

      // 6. Compatibilidad de cada ronda con su pregunta (restricciones duras).
      for (final r in rounds) {
        final q = r.question;
        expect(q, isNotNull, reason: 'la ronda de ${r.chapter.label} quedó sin pregunta');
        expect(q!.emotion, r.emotion, reason: 'la emoción nunca se cambia para hallar pregunta');
        expect(q.chapter, r.chapter, reason: 'la pregunta no pertenece al capítulo del espacio');
        expect(q.isSpecial, r.isSpecial, reason: 'el momento especial no se asigna a otra ronda');
        expect(r.allowedTypes, contains(q.type), reason: 'la pregunta no respeta los tipos permitidos del espacio');
      }

      // 7. La partida llegó al final.
      expect(engine.state.finished, isTrue);
      expect(engine.state.roundIndex, 25);
      expect(engine.state.canContinue, isFalse);
    },
  );
}
