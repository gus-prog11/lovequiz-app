import 'dart:math';
import 'package:LoveQuiz/data/questions.dart';
import 'package:LoveQuiz/models/emotional_model.dart';

class AIService {
  static final Random _random = Random();

  // Genera una pregunta personalizada según la categoría.
  static String generatePersonalizedQuestion({
    required String partner1,
    required String partner2,
    List<MemoryModel>? memories,
    String? category,
  }) {
    final templates = <String, List<String>>{
      'romanticas': [
        "Basado en su historia, $partner1, ¿qué recuerdo con $partner2 te hace más feliz?",
        "$partner2, si pudieras volver al día que conociste a $partner1, ¿qué le dirías?",
        "¿Cuál creen que es la canción que mejor describe su relación?",
        "$partner1, ¿qué es lo que $partner2 hace que nadie más puede igualar?",
        "Si su amor fuera una película, ¿qué título tendría?",
      ],
      'calientes': [
        "$partner1, ¿qué parte del cuerpo de $partner2 te provoca más?",
        "¿Cuál es la fantasía que $partner2 ha despertado en ti?",
        "$partner2, describe en una palabra lo que sientes cuando $partner1 te besa",
        "Si pudieran teletransportarse a un lugar privado ahora mismo, ¿dónde sería?",
        "$partner1, ¿qué movimiento de $partner2 te hace perder el control?",
      ],
      'divertidas': [
        "Si $partner1 y $partner2 fueran un equipo de superhéroes, ¿cuál sería su superpoder combinado?",
        "$partner2, ¿cuál es la cosa más graciosa que $partner1 hace sin darse cuenta?",
        "Si su relación fuera un programa de TV, ¿cómo se llamaría el episodio de hoy?",
        "$partner1, imita la cara que pone $partner2 cuando está confundido",
        "¿Qué tendría que pasar para que se pelearan por algo absurdo hoy?",
      ],
      'incomodas': [
        "$partner1, ¿hay algo que no le has dicho a $partner2 por miedo a su reacción?",
        "¿Qué creen que es el mayor desafío que enfrentarán como pareja?",
        "$partner2, ¿en qué momento sentiste que $partner1 no te entendía?",
        "Si pudieran cambiar un hábito del otro, ¿cuál sería?",
        "$partner1, ¿qué tema evitas hablar con $partner2?",
      ],
      'default': [
        "Basado en su conexión única, $partner1, ¿qué aprendiste de ti mismo gracias a $partner2?",
        "$partner2, ¿cómo crees que $partner1 describiría tu relación a un extraño?",
        "¿Qué cosa pequeña que $partner1 hace marcó la diferencia en tu día?",
        "Si pudieran crear un ritual diario juntos, ¿cuál sería?",
        "$partner1, ¿en qué momento supiste que $partner2 era especial?",
      ],
    };

    final pool = templates[category] ?? templates['default']!;
    return pool[_random.nextInt(pool.length)];
  }

  // Genera una lista de preguntas personalizadas para la pareja.
  static List<Question> generateAICustomQuestions({
    required String partner1,
    required String partner2,
    required String category,
    int count = 5,
  }) {
    final questions = <Question>[];
    for (int i = 0; i < count; i++) {
      questions.add(
        Question(
          text: generatePersonalizedQuestion(
            partner1: partner1,
            partner2: partner2,
            category: category,
          ),
          category: category,
        ),
      );
    }
    return questions;
  }

  // Calcula el porcentaje de compatibilidad de la pareja.
  static double calculateCompatibility({
    required int totalGames,
    required int totalQuestions,
    required int streak,
    required int memories,
    required int favoriteAnswers,
  }) {
    double score = 50.0;
    score += min(totalGames * 2, 15);
    score += min(totalQuestions * 0.1, 10);
    score += min(streak * 1.5, 15);
    score += min(memories * 3, 5);
    score += min(favoriteAnswers * 2, 5);
    return min(score, 100);
  }

  // Retorna un mensaje según el nivel de compatibilidad.
  static String getCompatibilityMessage(double score) {
    if (score >= 90) return "Conexión extraordinaria 💕";
    if (score >= 75) return "Gran conexión 💖";
    if (score >= 60) return "Buena conexión 💗";
    if (score >= 40) return "Conexión en crecimiento 💓";
    return "Sigan conociéndose 💔";
  }

  // Genera un iniciador de conversación para la pareja.
  static String generateConversationStarter({
    required String partner1,
    required String partner2,
    String? recentMemory,
  }) {
    final starters = [
      "$partner1, ¿sabías que $partner2 ama cuando...? ¡Cuéntale qué es lo que más disfrutas de él/ella!",
      "El otro día pensaba en lo mucho que $partner1 y $partner2 se complementan. ¿Cuál es su mejor recuerdo juntos?",
      "¿Sabían que las parejas que juegan juntas fortalecen su conexión? ¡$partner1, reta a $partner2 a responder esta!",
      "Si $partner1 pudiera describir a $partner2 con una sola palabra, ¿cuál sería? ¡Adivínalo!",
      "Una pregunta exclusiva para ustedes: ¿cuál fue el momento exacto en que supieron que eran el uno para el otro?",
    ];
    if (recentMemory != null) {
      starters.insert(
        0,
        "Hablando de $recentMemory, $partner1, ¿cómo te hizo sentir ese momento?",
      );
    }
    return starters[Random().nextInt(starters.length)];
  }
}
