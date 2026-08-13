import 'dart:math';

import '../enums/intensity.dart';
import '../models/game_question.dart';
import '../models/game_round.dart';
import '../repositories/question_repository.dart';

/// Estrategia que decide qué pregunta viene para un espacio del recorrido.
///
/// Es el "director de conversación" del documento Core GamePlay (§ "El motor
/// psicológico" y "Reglas del ritmo"). Reglas de esta fase:
///
///  - el recorrido emocional decide qué pregunta se necesita: la emoción del
///    espacio es la restricción más importante y NUNCA se cambia para
///    encontrar una pregunta;
///  - no repetir preguntas ya utilizadas en la partida;
///  - aplicar una escalera de degradación cuando no hay coincidencia exacta;
///  - ser determinista con un `Random` sembrado.
abstract class QuestionSelector {
  /// Elige la pregunta compatible con el `round` dado, excluyendo las de
  /// `usedQuestionIds`. Devuelve `null` si no existe ninguna pregunta
  /// razonablemente compatible (Nivel 5 de la escalera).
  Future<GameQuestion?> select({
    required GameRound round,
    required Set<String> usedQuestionIds,
  });
}

/// Implementación por defecto: búsqueda por niveles de prioridad.
///
/// La escalera de degradación depende del modo del espacio:
///
///  **Modo aleatorio** (`enforceCategory == false`):
///
///  **Nivel 1** — coincidencia exacta: emoción + intensidad + tipo +
///  categoría.
///
///  **Nivel 2** — mantener emoción + tipo + categoría y permitir una
///  intensidad cercana (±1 nivel).
///
///  **Nivel 3** — mantener emoción + tipo y permitir variación de
///  categoría/intensidad.
///
///  **Nivel 4** — mantener la emoción y seleccionar la pregunta con la
///  intensidad más cercana a la del espacio (ya sin restringir tipo ni
///  categoría, dentro del pool del capítulo).
///
///  **Nivel 5** — sin coincidencia razonable: la emoción del espacio es
///  sagrada, no se cambia para encontrar pregunta → devuelve `null`.
///
///  **Modo temático** (`enforceCategory == true`): la categoría es la
///  restricción fuerte y solo se suelta como último recurso.
///
///  **Nivel 1** — tema + emoción + intensidad + tipo.
///
///  **Nivel 2** — tema + emoción + intensidad cercana + tipo.
///
///  **Nivel 3** — tema + emoción (relaja tipo e intensidad).
///
///  **Nivel 4** — tema (relaja emoción; intensidad más cercana).
///
///  **Nivel 5** — el capítulo no tiene nada del tema → cae a cualquier
///  pregunta (emoción e intensidad más cercanas) para no romper la partida.
///
/// Si la categoría del espacio es `null` (sin preferencia), el criterio de
/// categoría no se aplica. Cuando un nivel tiene varias candidatas se elige
/// una uniformemente con `Random` (reproducible con semilla). La puntuación
/// interna es solo la distancia de intensidad, sencilla y determinista; la
/// lógica emocional avanzada se construirá tras probar el sistema.
class DefaultQuestionSelector implements QuestionSelector {
  DefaultQuestionSelector({required QuestionRepository repository, Random? random})
      : _repository = repository,
        _random = random ?? Random();

  final QuestionRepository _repository;
  final Random _random;

  @override
  Future<GameQuestion?> select({
    required GameRound round,
    required Set<String> usedQuestionIds,
  }) async {
    final pool = (await _repository.getQuestionsForRound(round))
        .where((q) => !usedQuestionIds.contains(q.id))
        .toList();
    if (pool.isEmpty) return null;

    // Modo temático: la categoría es restricción fuerte y se agota la escalera
    // manteniéndola. Modo aleatorio: la categoría es una preferencia blanda.
    if (round.enforceCategory && round.category != null) {
      return _selectThematic(pool, round);
    }
    return _selectFree(pool, round);
  }

  /// Escalera del modo aleatorio (categoría blanda): agota la categoría en los
  /// niveles 3/4 igual que el resto de criterios.
  GameQuestion? _selectFree(List<GameQuestion> pool, GameRound round) {
    // Nivel 1: coincidencia exacta.
    final exact = pool
        .where(
          (q) =>
              q.emotion == round.emotion &&
              q.intensity == round.intensity &&
              _typeMatches(q, round) &&
              _categoryMatches(q, round),
        )
        .toList();
    if (exact.isNotEmpty) return _pick(exact);

    // Nivel 2: intensidad cercana, misma categoría y tipo.
    final near = pool
        .where(
          (q) =>
              q.emotion == round.emotion &&
              (q.intensity.level - round.intensity.level).abs() <= 1 &&
              _typeMatches(q, round) &&
              _categoryMatches(q, round),
        )
        .toList();
    if (near.isNotEmpty) return _pick(near);

    // Nivel 3: emoción + tipo, con variación de categoría e intensidad.
    final relaxed = pool
        .where(
          (q) => q.emotion == round.emotion && _typeMatches(q, round),
        )
        .toList();
    if (relaxed.isNotEmpty) return _pick(relaxed);

    // Nivel 4: mantener la emoción, la más cercana en intensidad.
    final sameEmotion = pool
        .where((q) => q.emotion == round.emotion)
        .toList();
    if (sameEmotion.isNotEmpty) {
      return _pickClosestIntensity(sameEmotion, round.intensity);
    }

    // Nivel 5: sin coincidencia razonable. En modo aleatorio la emoción del
    // espacio es sagrada: no se cambia para encontrar una pregunta.
    return null;
  }

  /// Escalera del modo temático (categoría fuerte): el tema se mantiene hasta
  /// el último recurso. La emoción y la intensidad degradan antes que el tema.
  GameQuestion? _selectThematic(List<GameQuestion> pool, GameRound round) {
    final cat = round.category!;

    // Nivel 1: tema + emoción + intensidad + tipo.
    final exact = pool
        .where(
          (q) =>
              q.category == cat &&
              q.emotion == round.emotion &&
              q.intensity == round.intensity &&
              _typeMatches(q, round),
        )
        .toList();
    if (exact.isNotEmpty) return _pick(exact);

    // Nivel 2: tema + emoción + intensidad cercana + tipo.
    final near = pool
        .where(
          (q) =>
              q.category == cat &&
              q.emotion == round.emotion &&
              (q.intensity.level - round.intensity.level).abs() <= 1 &&
              _typeMatches(q, round),
        )
        .toList();
    if (near.isNotEmpty) return _pick(near);

    // Nivel 3: tema + emoción (relaja tipo e intensidad).
    final sameEmotion = pool
        .where(
          (q) => q.category == cat && q.emotion == round.emotion,
        )
        .toList();
    if (sameEmotion.isNotEmpty) return _pick(sameEmotion);

    // Nivel 4: tema (relaja emoción; intensidad más cercana).
    final sameCategory = pool.where((q) => q.category == cat).toList();
    if (sameCategory.isNotEmpty) {
      return _pickClosestIntensity(sameCategory, round.intensity);
    }

    // Nivel 5: el capítulo no tiene nada del tema → cae a cualquier pregunta
    // (emoción más cercana, intensidad más cercana) para no romper la partida.
    return _pickClosestEmotionIntensity(pool, round);
  }

  /// El tipo debe estar permitido por el espacio.
  bool _typeMatches(GameQuestion q, GameRound round) =>
      round.allowedTypes.contains(q.type);

  /// La categoría solo restringe cuando el espacio expresa preferencia.
  bool _categoryMatches(GameQuestion q, GameRound round) =>
      round.category == null || q.category == round.category;

  /// Elige uniformemente entre candidatas igualmente válidas.
  GameQuestion _pick(List<GameQuestion> candidates) =>
      candidates[_random.nextInt(candidates.length)];

  /// Entre las candidatas con la emoción pedida, devuelve una con la
  /// distancia de intensidad mínima (desempate uniforme).
  GameQuestion _pickClosestIntensity(
    List<GameQuestion> candidates,
    Intensity target,
  ) {
    final minDiff = candidates
        .map((q) => (q.intensity.level - target.level).abs())
        .reduce((a, b) => a < b ? a : b);
    final closest = candidates
        .where((q) => (q.intensity.level - target.level).abs() == minDiff)
        .toList();
    return _pick(closest);
  }

  /// Último recurso: entre todo el pool del capítulo, prioriza la emoción del
  /// espacio y luego la intensidad más cercana. Devuelve `null` si no hay
  /// nada jugable.
  GameQuestion? _pickClosestEmotionIntensity(
    List<GameQuestion> pool,
    GameRound round,
  ) {
    if (pool.isEmpty) return null;
    final sameEmotion = pool
        .where((q) => q.emotion == round.emotion)
        .toList();
    if (sameEmotion.isNotEmpty) {
      return _pickClosestIntensity(sameEmotion, round.intensity);
    }
    return _pickClosestIntensity(pool, round.intensity);
  }
}
