import '../enums/chapter.dart';
import '../enums/emotion.dart';
import '../enums/intensity.dart';
import '../enums/migration.dart';
import '../enums/question_category.dart';
import '../enums/question_type.dart';

/// Pregunta del nuevo motor de partidas.
///
/// A diferencia del modelo legacy `Question` (lib/data/questions.dart), este
/// incluye metadatos emocionales (emoción, intensidad), la categoría temática
/// y el capítulo al que pertenece, para que el selector pueda dirigir la
/// conversación. El origen de los datos lo oculta `QuestionRepository`.
class GameQuestion {
  final String id;
  final String text;
  final Chapter chapter;
  final Emotion emotion;
  final Intensity intensity;
  final QuestionType type;
  final QuestionCategory category;

  /// Opciones opcionales (comparación, retos con elección, etc.).
  final List<String> options;

  /// `true` para momentos escasos que deben sentirse inesperados
  /// (voz, comodines, promesas...).
  final bool isSpecial;

  /// Origen de la pregunta: `legacy` (migrada del banco antiguo, id `leg-*`)
  /// u `original` (creada para el nuevo motor, id `nue-*`).
  final QuestionSource source;

  /// Estado de revisión: solo las preguntas `listo` forman parte del banco
  /// jugable V1; el resto se conserva para revisión manual.
  final QuestionStatus status;

  const GameQuestion({
    required this.id,
    required this.text,
    required this.chapter,
    required this.emotion,
    required this.intensity,
    required this.category,
    this.type = QuestionType.conversacion,
    this.options = const [],
    this.isSpecial = false,
    this.source = QuestionSource.original,
    this.status = QuestionStatus.listo,
  });

  /// Serializa la pregunta a un mapa (puente online del motor).
  ///
  /// Los enums se guardan por su identificador (`name`), nunca por índice:
  /// así la representación es estable aunque se reordenen o añadan valores.
  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'chapter': chapter.name,
    'emotion': emotion.name,
    'intensity': intensity.name,
    'type': type.name,
    'category': category.name,
    'options': options,
    'isSpecial': isSpecial,
    'source': source.name,
    'status': status.name,
  };

  /// Reconstruye una pregunta desde un mapa guardado en la sala online.
  ///
  /// Fallos rápidos (`ArgumentError` si un enum no se reconoce) para no
  /// reconstruir partidas corruptas en silencio.
  factory GameQuestion.fromMap(Map<String, dynamic> map) => GameQuestion(
    id: map['id'] as String,
    text: map['text'] as String,
    chapter: Chapter.values.byName(map['chapter'] as String),
    emotion: Emotion.values.byName(map['emotion'] as String),
    intensity: Intensity.values.byName(map['intensity'] as String),
    type: QuestionType.values.byName(map['type'] as String),
    category: QuestionCategory.values.byName(map['category'] as String),
    options: List<String>.from(map['options'] as List),
    isSpecial: map['isSpecial'] as bool,
    source: QuestionSource.values.byName(map['source'] as String),
    status: QuestionStatus.values.byName(map['status'] as String),
  );
}
