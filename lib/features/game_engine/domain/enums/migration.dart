/// Metadatos de migración de preguntas.
///
/// La migración del banco legacy (`lib/data/questions.dart`) clasifica cada
/// pregunta con su origen y un estado de revisión, para distinguir las
/// preguntas ya validadas por el motor de las que necesitan una decisión
/// manual posterior.
library;

/// Origen de una pregunta del banco.
enum QuestionSource {
  /// Pregunta heredada del banco legacy (`lib/data/questions.dart`), migrada
  /// al modelo `GameQuestion`. Su `id` usa el prefijo `leg-`.
  legacy,

  /// Pregunta creada directamente para el nuevo motor (V1 o posterior).
  /// Su `id` usa el prefijo `nue-`.
  original,
}

/// Estado de revisión de una pregunta migrada.
///
/// La clasificación semántica (chapter/emotion/intensity/type/category) no es
/// determinista al 100%: estas marcas permiten separar lo que el motor puede
/// usar ya de lo que quedará pendiente de revisión humana.
enum QuestionStatus {
  /// Clasificación clara y compatible con el recorrido emocional actual.
  /// Es la única clase que el banco V1 expone al selector.
  listo,

  /// Puede funcionar, pero existe una duda razonable de clasificación o de
  /// tono. Se conserva para revisión manual, fuera del banco jugable.
  needsReview,

  /// No hay información suficiente para clasificarla correctamente.
  ambiguo,

  /// Claramente no pertenece al recorrido emocional actual (por tono,
  /// intensidad, mecánica o contenido). Se conserva sin eliminar, pero no se
  /// juega en V1.
  incompatible,
}
