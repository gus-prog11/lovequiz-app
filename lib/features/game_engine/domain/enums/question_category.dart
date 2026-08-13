/// Categoría temática de una pregunta del nuevo motor.
///
/// Refleja los ids de las categorías legacy de `lib/models/category.dart`
/// (romanticas, calientes, incomodas, divertidas, extremas, locas, retos) para
/// que la migración futura sea directa, sin arrastrar su modelo de
/// presentación (emoji/color). `generales` agrupa preguntas que no pertenecen
/// a una categoría temática (recuerdos de voz, comodines, cierre...).
enum QuestionCategory {
  romanticas(label: 'Románticas'),
  calientes(label: 'Calientes'),
  incomodas(label: 'Incómodas'),
  divertidas(label: 'Divertidas'),
  extremas(label: 'Extremas'),
  locas(label: 'Locas'),
  retos(label: 'Retos'),
  generales(label: 'Generales');

  const QuestionCategory({required this.label});

  final String label;
}
