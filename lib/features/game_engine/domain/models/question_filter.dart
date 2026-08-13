import '../enums/chapter.dart';
import '../enums/emotion.dart';
import '../enums/intensity.dart';
import '../enums/migration.dart';
import '../enums/question_category.dart';
import '../enums/question_type.dart';

/// Criterios de búsqueda combinables para el repositorio de preguntas.
///
/// Solo recuperación: cada criterio es opcional y, si se especifica, la
/// pregunta debe cumplirlo exactamente (las intensidades pueden pedirse por
/// rango con `minIntensity`/`maxIntensity`). No contiene lógica de decisión
/// emocional; esa pertenece al `QuestionSelector`.
class QuestionFilter {
  final Chapter? chapter;
  final Emotion? emotion;

  /// Coincidencia exacta de intensidad.
  final Intensity? intensity;

  /// Rango inclusivo de intensidad (nivel 1-4).
  final Intensity? minIntensity;
  final Intensity? maxIntensity;

  final QuestionType? type;
  final QuestionCategory? category;

  /// `true` solo para momentos escasos, `false` solo para los normales.
  final bool? isSpecial;

  /// Origen de la pregunta (legacy/original), para revisar el banco.
  final QuestionSource? source;

  /// Estado de revisión, para separar lo jugable (`listo`) de lo pendiente.
  final QuestionStatus? status;

  const QuestionFilter({
    this.chapter,
    this.emotion,
    this.intensity,
    this.minIntensity,
    this.maxIntensity,
    this.type,
    this.category,
    this.isSpecial,
    this.source,
    this.status,
  });
}
