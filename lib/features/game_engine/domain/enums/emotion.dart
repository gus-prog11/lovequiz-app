/// Tipos de momentos (emociones) que una pregunta puede generar.
///
/// El documento Core GamePlay (§ "Tipos de momentos") define diez emociones.
/// No todas pesan igual: Diversión y Descubrimiento aparecen muy seguido,
/// Conexión con frecuencia, Vulnerabilidad poco y Recuerdo (voz) muy poco.
/// El `weight` lo usa el selector para equilibrar la mezcla de emociones.
enum Emotion {
  conexion(emoji: '❤️', label: 'Conexión', weight: 12),
  diversion(emoji: '😂', label: 'Diversión', weight: 18),
  descubrimiento(emoji: '🤔', label: 'Descubrimiento', weight: 17),
  nostalgia(emoji: '🥹', label: 'Nostalgia', weight: 10),
  romance(emoji: '💕', label: 'Romance', weight: 10),
  coqueteo(emoji: '🔥', label: 'Coqueteo', weight: 8),
  futuro(emoji: '🌎', label: 'Futuro', weight: 10),
  vulnerabilidad(emoji: '🎭', label: 'Vulnerabilidad', weight: 4),
  celebracion(emoji: '🎉', label: 'Celebración', weight: 7),
  recuerdo(emoji: '🎙️', label: 'Recuerdo', weight: 2);

  const Emotion({
    required this.emoji,
    required this.label,
    required this.weight,
  });

  final String emoji;
  final String label;

  /// Peso relativo de aparición: mientras mayor, más frecuente.
  ///
  /// Valores provisionales basados en las frecuencias relativas del
  /// documento; se afinarán con datos reales de partidas.
  final double weight;
}

/// Reglas de transición suave entre emociones: las emociones que pueden
/// seguir a la actual sin que el cambio se sienta brusco.
///
/// El builder elige la siguiente emoción dando prioridad a las que están en
/// este conjunto (dentro del pool del capítulo) y cae al pool completo cuando
/// ninguna es compatible (fallback, para no bloquear la partida). Es un mapa
/// de nivel superior (y no un campo del enum) porque una referencia circular
/// entre valores del enum no es una constante válida en Dart.
const Map<Emotion, Set<Emotion>> smoothTransitions = {
  Emotion.conexion: {
    Emotion.romance,
    Emotion.coqueteo,
    Emotion.descubrimiento,
    Emotion.nostalgia,
    Emotion.recuerdo,
    Emotion.diversion,
  },
  Emotion.diversion: {
    Emotion.descubrimiento,
    Emotion.celebracion,
    Emotion.conexion,
  },
  Emotion.descubrimiento: {
    Emotion.diversion,
    Emotion.conexion,
    Emotion.nostalgia,
    Emotion.futuro,
    Emotion.celebracion,
  },
  Emotion.nostalgia: {
    Emotion.conexion,
    Emotion.recuerdo,
    Emotion.futuro,
    Emotion.celebracion,
    Emotion.descubrimiento,
  },
  Emotion.romance: {
    Emotion.conexion,
    Emotion.coqueteo,
    Emotion.recuerdo,
    Emotion.futuro,
    Emotion.nostalgia,
  },
  Emotion.coqueteo: {
    Emotion.romance,
    Emotion.conexion,
    Emotion.diversion,
  },
  Emotion.futuro: {
    Emotion.conexion,
    Emotion.romance,
    Emotion.celebracion,
    Emotion.nostalgia,
  },
  Emotion.vulnerabilidad: {
    Emotion.conexion,
    Emotion.romance,
    Emotion.recuerdo,
  },
  Emotion.celebracion: {
    Emotion.diversion,
    Emotion.conexion,
    Emotion.futuro,
    Emotion.nostalgia,
    Emotion.descubrimiento,
  },
  Emotion.recuerdo: {
    Emotion.conexion,
    Emotion.romance,
    Emotion.nostalgia,
    Emotion.celebracion,
    Emotion.futuro,
  },
};
