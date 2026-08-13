import 'dart:async';
import 'dart:math';

import '../domain/builders/match_builder.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_chapter.dart';
import '../domain/models/game_engine_state.dart';import '../domain/models/game_question.dart';
import '../domain/models/game_round.dart';
import '../domain/models/game_settings.dart';
import '../domain/repositories/question_repository.dart';
import '../domain/selectors/question_selector.dart';

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
       _selector = selector ??
           DefaultQuestionSelector(repository: repository, random: random),
       _random = random ?? Random(),
       _excludedTypes = excludedTypes;

  final GameSettings _settings;
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

    final rounds = MatchBuilder(
      chapters: _chapters,
      preferredCategories: _settings.preferredCategories,
      random: _random,
    ).build();
    _state = GameEngineState(
      rounds: rounds,
      currentChapter: rounds.isNotEmpty ? rounds.first.chapter : null,
      totalRounds: rounds.length,
    );
    _emit();
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
