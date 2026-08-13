/// Formato de entrega de una pregunta.
///
/// El documento Core GamePlay (§ "Mecánicas del juego") describe mecánicas
/// con formatos distintos: retos (acciones), recuerdos de voz y comodines.
/// El tipo correcto depende del momento que se busca generar.
enum QuestionType {
  /// Pregunta libre que abre y acompaña una conversación.
  conversacion,

  /// Pequeña acción, no solo responder ("nunca deben incomodar").
  reto,

  /// Recuerdo de voz: algo que la pareja quiera volver a escuchar.
  voz,

  /// Evento que cambia temporalmente la dinámica de la partida.
  comodin,

  /// Respuestas de ambos que luego se comparan/muestran (evolución del
  /// problema de diseño "las respuestas nunca se comparan").
  comparacion,
}
