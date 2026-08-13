import '../enums/chapter.dart';
import '../enums/emotion.dart';
import 'game_round.dart';

/// Fotografía inmutable del estado de una partida.
///
/// El motor publica este estado por stream para que la UI reaccione. El
/// selector lo lee para decidir la siguiente pregunta ("director de
/// conversación").
class GameEngineState {
  /// Capítulo en el que está la partida. `null` antes de empezar.
  final Chapter? currentChapter;

  /// Recorrido emocional completo de la partida (los espacios), construido
  /// por `MatchBuilder` ANTES de asignar preguntas.
  final List<GameRound> rounds;

  /// Índice de la ronda actual dentro de la partida.
  final int roundIndex;

  /// Total de rondas previstas.
  final int totalRounds;

  /// Puntaje acumulado (por definir; el documento evita premiar cantidad).
  final int score;

  /// IDs de preguntas ya usadas para no repetir.
  final Set<String> askedQuestionIds;

  /// Historial de rondas de la partida actual.
  final List<GameRound> history;

  /// Última emoción vivida: el selector la usa para alternar emociones.
  final Emotion? lastEmotion;

  /// `true` cuando la partida terminó.
  final bool finished;

  const GameEngineState({
    this.currentChapter,
    this.rounds = const [],
    this.roundIndex = 0,
    this.totalRounds = 0,
    this.score = 0,
    this.askedQuestionIds = const {},
    this.history = const [],
    this.lastEmotion,
    this.finished = false,
  });

  factory GameEngineState.initial() => const GameEngineState();

  bool get canContinue => !finished && roundIndex < totalRounds;

  GameEngineState copyWith({
    Chapter? currentChapter,
    bool clearChapter = false,
    List<GameRound>? rounds,
    int? roundIndex,
    int? totalRounds,
    int? score,
    Set<String>? askedQuestionIds,
    List<GameRound>? history,
    Emotion? lastEmotion,
    bool clearLastEmotion = false,
    bool? finished,
  }) => GameEngineState(
    currentChapter: clearChapter ? null : currentChapter ?? this.currentChapter,
    rounds: rounds ?? this.rounds,
    roundIndex: roundIndex ?? this.roundIndex,
    totalRounds: totalRounds ?? this.totalRounds,
    score: score ?? this.score,
    askedQuestionIds: askedQuestionIds ?? this.askedQuestionIds,
    history: history ?? this.history,
    lastEmotion: clearLastEmotion
        ? null
        : lastEmotion ?? this.lastEmotion,
    finished: finished ?? this.finished,
  );
}
