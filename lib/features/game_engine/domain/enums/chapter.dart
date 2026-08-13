/// Capítulos (etapas) por las que transcurre una partida.
///
/// El documento Core GamePlay (§ "¿Cómo se construye una partida?") describe
/// el viaje emocional de una partida en cinco etapas. Cada una tiene una
/// duración, un objetivo psicológico y un conjunto de emociones e
/// intensidades permitidas.
enum Chapter {
  bienvenida(
    label: 'Bienvenida',
    description: 'Reducir tensión y hacer que ambos sonrían.',
    defaultMinutes: 3,
  ),
  calentamiento(
    label: 'Calentamiento',
    description: 'Que ambos hablen cada vez más: gustos, opiniones e historias.',
    defaultMinutes: 6,
  ),
  conexion(
    label: 'Conexión',
    description: 'Momentos de romance, nostalgia, futuro y pequeños retos.',
    defaultMinutes: 12,
  ),
  momentoEspecial(
    label: 'Momento especial',
    description: 'El momento que la pareja recordará: promesa, plan, voz...',
    defaultMinutes: 3,
  ),
  cierre(
    label: 'Cierre',
    description: 'Terminar arriba con una emoción positiva (Peak-End Rule).',
    defaultMinutes: 2,
  );

  const Chapter({
    required this.label,
    required this.description,
    required this.defaultMinutes,
  });

  final String label;
  final String description;
  final int defaultMinutes;
}
