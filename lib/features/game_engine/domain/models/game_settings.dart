import '../enums/chapter.dart';
import '../enums/intensity.dart';
import '../enums/question_category.dart';

/// Configuración de una partida elegida por el jugador.
///
/// Reemplazará de forma gradual a los parámetros actuales de configuración
/// (categorías, total de preguntas, temporizador).
class GameSettings {
  /// Etapas que se jugarán, en orden.
  final List<Chapter> chapters;

  /// Total de preguntas de la partida (objetivo de duración).
  final int totalQuestions;

  /// Número de rondas que tendrá la partida (objetivo de duración del motor).
  ///
  /// 25 = recorrido completo (5+6+8+1+5). Con un valor menor, los capítulos se
  /// escalan proporcionalmente conservando el arco emocional (el momento
  /// especial sigue siendo el pico).
  final int totalRounds;

  /// Temporizador por pregunta en segundos. 0 = sin temporizador.
  final int timerSeconds;

  /// Intensidad máxima permitida en toda la partida.
  final Intensity maxIntensity;

  /// Categorías temáticas preferidas por el jugador.
  ///
  /// Si no está vacío, la partida se juega en **modo temático**: el
  /// `MatchBuilder` marca la categoría como restricción fuerte y la escalera
  /// del selector la mantiene hasta el último recurso (el recorrido emocional
  /// y la rampa de intensidad se conservan; la emoción del espacio degrada
  /// antes que el tema). Vacío = **modo aleatorio**: todas las categorías
  /// tienen la misma oportunidad y la emoción gobierna la transición.
  final List<QuestionCategory> preferredCategories;

  const GameSettings({
    required this.chapters,
    this.totalQuestions = 30,
    this.totalRounds = 25,
    this.timerSeconds = 0,
    this.maxIntensity = Intensity.intensa,
    this.preferredCategories = const [],
  });
}
