import 'dart:async';
import 'dart:math';

import '../domain/builders/match_builder.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_chapter.dart';
import '../domain/models/game_engine_state.dart';import '../domain/models/game_question.dart';
import '../domain/models/game_round.dart';
import '../domain/models/game_settings.dart';
import '../domain/models/question_filter.dart';
import '../domain/repositories/question_repository.dart';
import '../domain/selectors/question_selector.dart';

/// Cuota mínima de comparaciones garantizadas por partida según su tamaño.
///
/// - 25 o más rondas → 3 comparaciones;
/// - 20 o más rondas → 2 comparaciones;
/// - 10 o más rondas → 1 comparación;
/// - menos de 10 → sin garantía.
///
/// El motor la aplica marcando espacios de Conexión/Cierre como espacios de
/// comparación (siempre que el banco tenga comparación de esa emoción, para
/// no abrir huecos ni romper la emoción del espacio).
int comparisonQuotaFor(int totalRounds) {
  if (totalRounds >= 25) return 3;
  if (totalRounds >= 20) return 2;
  if (totalRounds >= 10) return 1;
  return 0;
}

/// Motor de partidas de LoveQuiz.
///
/// Orquesta una partida: usa `MatchBuilder` para construir el recorrido
/// emocional completo (los espacios) antes de asignar preguntas, después usa
/// el selector (que consulta al repositorio) para decidir la siguiente
/// pregunta de cada espacio y publica el estado mediante un stream. Es Dart
/// puro (sin Flutter) para poder probarlo con unit tests.
///
/// Hoy el motor se prueba desde `EngineTestScreen` y alimenta el modo local de
/// `GamePlayScreen` a través de `buildEngineMatch`; el flujo online legacy
/// sigue intacto y no usa este motor.
class GameEngine {
  GameEngine({
    required GameSettings settings,
    required QuestionRepository repository,
    QuestionSelector? selector,
    Random? random,
    Set<QuestionType> excludedTypes = const {},
  }) : _settings = settings,
       _repository = repository,
       _selector = selector ??
           DefaultQuestionSelector(repository: repository, random: random),
       _random = random ?? Random(),
       _excludedTypes = excludedTypes;

  final GameSettings _settings;
  final QuestionRepository _repository;
  final QuestionSelector _selector;
  final Random _random;

  /// Formatos de pregunta que la partida no debe usar (p. ej. comparaciones
  /// en modo online, que aún no se sincronizan a dos dispositivos). Se
  /// aplican al construir los capítulos en [start], así que la escalera del
  /// selector nunca llega a ofrecerlos.
  final Set<QuestionType> _excludedTypes;

  final StreamController<GameEngineState> _stateController =
      StreamController<GameEngineState>.broadcast();

  /// Capítulos configurados para la partida en curso.
  final List<GameChapter> _chapters = [];

  GameEngineState _state = GameEngineState.initial();

  /// Estado actual de la partida.
  GameEngineState get state => _state;

  /// Stream de estados: la UI se suscribe para reaccionar a cada cambio.
  Stream<GameEngineState> get stateStream => _stateController.stream;

  /// Inicia una nueva partida: construye el recorrido emocional completo
  /// (los espacios) ANTES de asignar preguntas.
  Future<void> start() async {
    var chapters = _settings.chapters
        .map(GameChapter.forChapter)
        .map((chapter) => chapter.excluding(_excludedTypes))
        .toList();
    // Partidas cortas: los capítulos se escalan para que la partida tenga
    // exactamente `totalRounds` espacios conservando el arco emocional.
    chapters = scaleChaptersForRounds(chapters, _settings.totalRounds);
    _chapters
      ..clear()
      ..addAll(chapters);

    var rounds = MatchBuilder(
      chapters: _chapters,
      preferredCategories: _settings.preferredCategories,
      random: _random,
    ).build();

    // Cuota de comparaciones: el formato "ambos responden y se comparan" tiene
    // presencia garantizada en la mezcla (1/2/3 según 10/20/25 rondas).
    final quota = comparisonQuotaFor(_settings.totalRounds);
    if (quota > 0) {
      rounds = await _applyComparisonQuota(rounds, quota);
    }

    _state = GameEngineState(
      rounds: rounds,
      currentChapter: rounds.isNotEmpty ? rounds.first.chapter : null,
      totalRounds: rounds.length,
    );
    _emit();
  }

  /// Marca hasta `quota` espacios como espacios de comparación (solo
  /// permiten `QuestionType.comparacion`), repartidos a lo largo de la
  /// partida.
  ///
  /// Solo se eligen espacios de capítulos que ya admiten comparación
  /// (Conexión/Cierre), que no sean el momento especial y cuya emoción tenga
  /// al menos una comparación disponible en el banco (en modo temático, del
  /// tema del espacio). Así la cuota no abre huecos en la partida ni cambia
  /// la emoción del espacio: el selector elegirá siempre una comparación con
  /// esa emoción.
  Future<List<GameRound>> _applyComparisonQuota(
    List<GameRound> rounds,
    int quota,
  ) async {
    final eligible = <int>[];
    for (var i = 0; i < rounds.length; i++) {
      final r = rounds[i];
      if (r.isSpecial) continue;
      if (!r.allowedTypes.contains(QuestionType.comparacion)) continue;
      final matching = await _repository.getQuestions(
        QuestionFilter(
          chapter: r.chapter,
          emotion: r.emotion,
          type: QuestionType.comparacion,
          category: r.enforceCategory ? r.category : null,
        ),
      );
      if (matching.isEmpty) continue;
      eligible.add(i);
    }
    if (eligible.isEmpty) return rounds;

    // Reparte la cuota espaciada entre los espacios elegibles (determinista).
    final forced = <int>{};
    final step = eligible.length / quota;
    for (var k = 0; k < quota && k < eligible.length; k++) {
      final index = eligible[(step * k).floor().clamp(0, eligible.length - 1)];
      forced.add(index);
    }
    if (forced.isEmpty) return rounds;

    return [
      for (var i = 0; i < rounds.length; i++)
        forced.contains(i)
            ? rounds[i].copyWith(
                allowedTypes: const [QuestionType.comparacion],
              )
            : rounds[i],
    ];
  }

  /// Pide la pregunta del espacio actual: el selector la busca en el
  /// repositorio según las características del `GameRound`. Asigna la
  /// pregunta al espacio en el estado y devuelve `null` si no hay ninguna
  /// compatible (Nivel 5).
  Future<GameQuestion?> next() async {
    if (!_state.canContinue) return null;

    final round = _state.rounds[_state.roundIndex];
    final question = await _selector.select(
      round: round,
      usedQuestionIds: _state.askedQuestionIds,
    );

    final rounds = [..._state.rounds];
    rounds[_state.roundIndex] = round.copyWith(question: question);
    _state = _state.copyWith(
      rounds: rounds,
      currentChapter: round.chapter,
    );
    _emit();

    return question;
  }

  /// Registra la respuesta (o salto) de la ronda actual y publica el estado.
  Future<void> answer(GameRound round) async {
    final question = round.question;
    final nextIndex = _state.roundIndex + 1;
    _state = _state.copyWith(
      history: [..._state.history, round],
      roundIndex: nextIndex,
      finished: nextIndex >= _state.totalRounds,
      lastEmotion: question?.emotion ?? round.emotion,
      askedQuestionIds: question != null
          ? {..._state.askedQuestionIds, question.id}
          : _state.askedQuestionIds,
    );
    _emit();
  }

  void _emit() {
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  /// Libera el stream de estados.
  void dispose() {
    _stateController.close();
  }
}
