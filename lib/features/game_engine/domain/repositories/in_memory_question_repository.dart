import '../models/game_question.dart';
import '../models/game_round.dart';
import '../models/question_filter.dart';
import 'question_repository.dart';

/// Repositorio en memoria para la fase de prueba.
///
/// Almacena una lista fija de preguntas y las filtra de forma determinista
/// (mismo orden de inserción). Sin lógica de decisión: solo almacenar y
/// recuperar.
class InMemoryQuestionRepository implements QuestionRepository {
  InMemoryQuestionRepository(this.questions);

  /// Preguntas almacenadas, en orden de inserción.
  final List<GameQuestion> questions;

  @override
  Future<List<GameQuestion>> getQuestions(QuestionFilter filter) async {
    return questions.where((q) => _matches(q, filter)).toList();
  }

  @override
  Future<List<GameQuestion>> getQuestionsForRound(GameRound round) async {
    return getQuestions(
      QuestionFilter(chapter: round.chapter, isSpecial: round.isSpecial),
    );
  }

  bool _matches(GameQuestion q, QuestionFilter f) {
    if (f.chapter != null && q.chapter != f.chapter) return false;
    if (f.emotion != null && q.emotion != f.emotion) return false;
    if (f.intensity != null && q.intensity != f.intensity) return false;
    if (f.minIntensity != null && q.intensity.level < f.minIntensity!.level) {
      return false;
    }
    if (f.maxIntensity != null && q.intensity.level > f.maxIntensity!.level) {
      return false;
    }
    if (f.type != null && q.type != f.type) return false;
    if (f.category != null && q.category != f.category) return false;
    if (f.isSpecial != null && q.isSpecial != f.isSpecial) return false;
    if (f.source != null && q.source != f.source) return false;
    if (f.status != null && q.status != f.status) return false;
    return true;
  }
}
