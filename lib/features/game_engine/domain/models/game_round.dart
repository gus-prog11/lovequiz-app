import '../enums/chapter.dart';
import '../enums/emotion.dart';
import '../enums/intensity.dart';
import '../enums/question_category.dart';
import '../enums/question_type.dart';
import 'game_question.dart';

/// Espacio del recorrido emocional de una partida.
///
/// Un espacio define qué momento se quiere vivir: en qué capítulo ocurre, qué
/// emoción se busca generar, a qué intensidad y qué tipos de pregunta son
/// válidos. `MatchBuilder` construye la partida completa como una lista de
/// espacios ANTES de asignar preguntas reales; el campo `question` se rellena
/// más adelante cuando el selector elige una pregunta que cumple con el
/// espacio. Los campos en vivo (`answered`, `skipped`, `startedAt`) se
/// actualizan durante el juego.
class GameRound {
  /// Capítulo al que pertenece este espacio.
  final Chapter chapter;

  /// Emoción que este espacio busca generar.
  final Emotion emotion;

  /// Intensidad esperada de este espacio.
  final Intensity intensity;

  /// Categoría temática preferida del espacio. `null` = sin preferencia
  /// (el selector ignora la categoría como criterio).
  final QuestionCategory? category;

  /// `true` = categoría temática fuerte (modo temático): el selector agota la
  /// escalera manteniendo la categoría y solo la suelta como último recurso.
  /// `false` = categoría blanda (modo aleatorio): la escalera degrada la
  /// categoría en los niveles 3/4 igual que el resto de criterios.
  final bool enforceCategory;

  /// Tipos de pregunta que pueden ocupar este espacio.
  final List<QuestionType> allowedTypes;

  /// `true` para momentos escasos que deben sentirse inesperados (voz).
  final bool isSpecial;

  /// Pregunta asignada a este espacio. `null` mientras se está construyendo
  /// la partida o si el jugador la omitió.
  final GameQuestion? question;

  /// `true` cuando ya fue respondida.
  final bool answered;

  /// `true` cuando el jugador decidió omitirla (el documento exige que "los
  /// jugadores siempre se sientan libres de omitir una pregunta").
  final bool skipped;

  /// Momento en el que se presentó el espacio al jugador.
  final DateTime? startedAt;

  const GameRound({
    required this.chapter,
    required this.emotion,
    required this.intensity,
    this.category,
    this.enforceCategory = false,
    this.allowedTypes = const [],
    this.isSpecial = false,
    this.question,
    this.answered = false,
    this.skipped = false,
    this.startedAt,
  });

  factory GameRound.initial(GameRound round) => GameRound(
    chapter: round.chapter,
    emotion: round.emotion,
    intensity: round.intensity,
    category: round.category,
    enforceCategory: round.enforceCategory,
    allowedTypes: round.allowedTypes,
    isSpecial: round.isSpecial,
    question: round.question,
    startedAt: DateTime.now(),
  );

  GameRound copyWith({
    GameQuestion? question,
    bool clearQuestion = false,
    bool? answered,
    bool? skipped,
    List<QuestionType>? allowedTypes,
  }) => GameRound(
    chapter: chapter,
    emotion: emotion,
    intensity: intensity,
    category: category,
    enforceCategory: enforceCategory,
    allowedTypes: allowedTypes ?? this.allowedTypes,
    isSpecial: isSpecial,
    question: clearQuestion ? null : question ?? this.question,
    answered: answered ?? this.answered,
    skipped: skipped ?? this.skipped,
    startedAt: startedAt,
  );

  /// Serializa el espacio a un mapa (puente online del motor).
  ///
  /// Los enums se guardan por su identificador (`name`), nunca por índice.
  /// Los campos opcionales (`category`, `question`, `startedAt`) solo se
  /// incluyen cuando no son `null`; el resto siempre, para que la
  /// reconstrucción sea exacta.
  Map<String, dynamic> toMap() => {
    'chapter': chapter.name,
    'emotion': emotion.name,
    'intensity': intensity.name,
    if (category != null) 'category': category!.name,
    'enforceCategory': enforceCategory,
    'allowedTypes': allowedTypes.map((type) => type.name).toList(),
    'isSpecial': isSpecial,
    if (question != null) 'question': question!.toMap(),
    'answered': answered,
    'skipped': skipped,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
  };

  /// Reconstruye un espacio desde un mapa guardado en la sala online.
  ///
  /// Fallos rápidos (`ArgumentError` si un enum no se reconoce) para no
  /// reconstruir partidas corruptas en silencio.
  factory GameRound.fromMap(Map<String, dynamic> map) => GameRound(
    chapter: Chapter.values.byName(map['chapter'] as String),
    emotion: Emotion.values.byName(map['emotion'] as String),
    intensity: Intensity.values.byName(map['intensity'] as String),
    category: map['category'] != null
        ? QuestionCategory.values.byName(map['category'] as String)
        : null,
    enforceCategory: map['enforceCategory'] as bool,
    allowedTypes: (map['allowedTypes'] as List)
        .map((type) => QuestionType.values.byName(type as String))
        .toList(),
    isSpecial: map['isSpecial'] as bool,
    question: map['question'] != null
        ? GameQuestion.fromMap(Map<String, dynamic>.from(map['question'] as Map))
        : null,
    answered: map['answered'] as bool,
    skipped: map['skipped'] as bool,
    startedAt: map['startedAt'] != null
        ? DateTime.parse(map['startedAt'] as String)
        : null,
  );
}
