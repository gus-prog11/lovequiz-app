/// Nivel de profundidad/intensidad emocional de una pregunta.
///
/// El documento Core GamePlay (§ "Reglas del ritmo") exige que la intensidad
/// crezca poco a poco: la partida comienza ligera, gana profundidad
/// gradualmente y termina con los momentos más memorables.
enum Intensity {
  suave(level: 1, label: 'Suave'),
  media(level: 2, label: 'Media'),
  alta(level: 3, label: 'Alta'),
  intensa(level: 4, label: 'Intensa');

  const Intensity({required this.level, required this.label});

  /// Orden numérico para comparar intensidades (mayor = más profunda).
  final int level;
  final String label;
}
