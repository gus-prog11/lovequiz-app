import 'dart:math';

import '../data/question_bank_v1.dart';
import '../domain/enums/chapter.dart';
import '../domain/enums/migration.dart';
import '../domain/enums/question_category.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_question.dart';
import '../domain/models/game_round.dart';
import '../domain/models/game_settings.dart';
import '../domain/repositories/in_memory_question_repository.dart';
import 'game_engine.dart';

/// Construye una partida completa jugable con el motor.
///
/// Corre el `GameEngine` con el banco V1 sobre todos los capítulos y devuelve
/// las rondas ya asignadas a preguntas reales, en orden de juego. Es el puente
/// entre el motor (que selecciona pregunta por pregunta) y la UI (que consume
/// una lista de rondas listas para jugar).
///
/// Las rondas sin pregunta compatible (Nivel 5) se descartan: la partida
/// resultante solo contiene momentos jugables. Con el banco V1 completo esto
/// no debería ocurrir (las 40 partidas simuladas no tuvieron huecos).
///
/// `excludedTypes` permite no jugar formatos que un modo concreto no soporta
/// (p. ej. fallback de voz sin audio): se quitan de los tipos permitidos de
/// cada capítulo antes de asignar preguntas, conservando el recorrido emocional.
Future<List<GameRound>> buildEngineMatch({
  List<QuestionCategory> preferredCategories = const [],
  Set<QuestionType> excludedTypes = const {},
  int totalRounds = 25,
  Random? random,
}) async {
  final engine = GameEngine(
    settings: GameSettings(
      chapters: Chapter.values,
      preferredCategories: preferredCategories,
      totalRounds: totalRounds,
    ),
    repository: InMemoryQuestionRepository(bancoV1Questions),
    random: random ?? Random(),
    excludedTypes: excludedTypes,
  );

  try {
    await engine.start();

    final played = <GameRound>[];
    while (engine.state.canContinue) {
      final round = engine.state.rounds[engine.state.roundIndex];
      final question = await engine.next();
      // Se responde con la ronda que ya lleva la pregunta asignada para que
      // el motor registre el id en askedQuestionIds (y no vuelva a ofrecerla).
      final answered = round.copyWith(
        question: question,
        skipped: question == null,
      );
      await engine.answer(answered);
      if (question != null) played.add(answered);
    }
    return played;
  } finally {
    engine.dispose();
  }
}

/// Alternativa escrita para el Momento especial cuando alguien no quiere (o no
/// puede) hablar en ese momento.
///
/// Busca en todo el banco una pregunta escrita del mismo tema (si hay
/// preferencias) y con la emoción e intensidad más cercanas al espacio, para
/// que el desenlace se conserve sin romperlo. Nunca devuelve una pregunta de
/// voz, excluye la pregunta ya asignada al espacio y las preguntas que ya se
/// usaron antes en la partida (`usedQuestionIds`), para que el fallback no
/// repita una pregunta que ya salió. `excludedTypes` permite excluir más
/// formatos no soportados (p. ej. comparaciones en online).
Future<GameQuestion?> pickNoVoiceFallback({
  required GameRound round,
  List<QuestionCategory> preferredCategories = const [],
  Set<QuestionType> excludedTypes = const {QuestionType.voz},
  Set<String> usedQuestionIds = const {},
  Random? random,
}) async {
  final rng = random ?? Random();
  final currentId = round.question?.id;

  final base = bancoV1Questions.where(
    (q) =>
        q.status == QuestionStatus.listo &&
        !excludedTypes.contains(q.type) &&
        q.id != currentId &&
        !usedQuestionIds.contains(q.id),
  );

  List<GameQuestion> candidates;
  if (preferredCategories.isNotEmpty) {
    final themed = base
        .where((q) => preferredCategories.contains(q.category))
        .toList();
    candidates = themed.isNotEmpty ? themed : base.toList();
  } else {
    candidates = base.toList();
  }
  if (candidates.isEmpty) return null;

  int score(GameQuestion q) =>
      (q.emotion == round.emotion ? 0 : 1) * 100 +
      (q.intensity.level - round.intensity.level).abs();

  final minScore = candidates.map(score).reduce((a, b) => a < b ? a : b);
  final closest = candidates.where((q) => score(q) == minScore).toList();
  return closest[rng.nextInt(closest.length)];
}
