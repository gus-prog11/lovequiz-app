import '../models/game_question.dart';
import '../models/game_round.dart';
import '../models/question_filter.dart';

/// Frontera de acceso a preguntas.
///
/// Oculta el origen de los datos: hoy una lista en memoria
/// (`InMemoryQuestionRepository`) y en el futuro Firestore o preguntas con IA.
/// El motor solo conoce esta interfaz, así la migración es plug & play.
///
/// Responsabilidad únicamente de **almacenar y recuperar** preguntas: no
/// contiene lógica de decisiones emocionales. La escalera de degradación y la
/// elección final son del `QuestionSelector`.
abstract class QuestionRepository {
  /// Recupera preguntas que cumplen TODOS los criterios del filtro.
  Future<List<GameQuestion>> getQuestions(QuestionFilter filter);

  /// Recupera el pool base de preguntas compatibles con un espacio: mismo
  /// capítulo y mismo tipo de momento (especial/no especial). El selector
  /// aplica sobre este pool la escalera de coincidencia emocional.
  Future<List<GameQuestion>> getQuestionsForRound(GameRound round);
}
