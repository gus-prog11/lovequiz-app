import '../domain/enums/chapter.dart';
import '../domain/enums/emotion.dart';
import '../domain/enums/intensity.dart';
import '../domain/enums/migration.dart';
import '../domain/enums/question_category.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_question.dart';

/// Momentos de voz del modo temático (el desenlace de cada categoría).
///
/// En modo temático la categoría elegida es la restricción fuerte, y el
/// Momento especial (clímax de voz, 1 por partida) debe poder ser también del
/// tema elegido. Ningún banco legacy de categoría tenía preguntas de voz, así
/// que estas cubren el clímax para las categorías que ya tienen banco:
/// `romanticas`, `divertidas`, `locas`, `retos`, `calientes`, `incomodas` y
/// `extremas`.
///
/// Reglas: ids `nue-voice-<categoría>-<n>`, `chapter.momentoEspecial`,
/// `type: voz`, `isSpecial: true` y `status: listo`. Cada categoría cubre las
/// cuatro emociones que el capítulo admite (recuerdo, romance, futuro y
/// celebración) a intensidad `intensa` (la rampa del capítulo siempre aterriza
/// ahí), para que el selector las encuentre en Nivel 1.
///
/// `incomodas` no tenía banco hasta V2; ahora que el lote temático la cubre,
/// su desenlace usa sus propias voces. Todas las categorías con banco temático
/// tienen desenlace propio.
final List<GameQuestion> thematicVoicesV1 = <GameQuestion>[
  // ════════════════════════════════════════════════════════════════════════
  // Románticas
  // ════════════════════════════════════════════════════════════════════════
  _v('romanticas-romance', 'Mírale a los ojos y dile en voz baja el momento en que supiste que era tu persona.', QuestionCategory.romanticas, Emotion.romance),
  _v('romanticas-futuro', 'Prométele en voz alta algo que quieras cumplirle a tu pareja este año.', QuestionCategory.romanticas, Emotion.futuro),
  _v('romanticas-recuerdo', 'Cuéntale con tu voz el recuerdo de ustedes que más repites en tu cabeza.', QuestionCategory.romanticas, Emotion.recuerdo),
  _v('romanticas-celebracion', 'Dile en voz alta qué es lo que más celebras de haberte encontrado con tu pareja.', QuestionCategory.romanticas, Emotion.celebracion),

  // ════════════════════════════════════════════════════════════════════════
  // Divertidas
  // ════════════════════════════════════════════════════════════════════════
  _v('divertidas-celebracion', 'Dile en voz alta cuál es el momento de ustedes que más te hace reír y por qué.', QuestionCategory.divertidas, Emotion.celebracion),
  _v('divertidas-futuro', 'Propónle en voz alta el plan más divertido que quieran hacer juntos este año.', QuestionCategory.divertidas, Emotion.futuro),
  _v('divertidas-recuerdo', 'Cuéntale en voz alta la anécdota que más risas les ha arrancado en estos meses.', QuestionCategory.divertidas, Emotion.recuerdo),
  _v('divertidas-romance', 'Dile en voz alta, entre risas, lo que más le agradeces a tu pareja.', QuestionCategory.divertidas, Emotion.romance),

  // ════════════════════════════════════════════════════════════════════════
  // Locas
  // ════════════════════════════════════════════════════════════════════════
  _v('locas-futuro', 'Propónle en voz alta la cosa más loca que harían juntos sin pensarlo dos veces.', QuestionCategory.locas, Emotion.futuro),
  _v('locas-celebracion', 'Confiesa en voz alta la locura de ustedes que más veces has contado.', QuestionCategory.locas, Emotion.celebracion),
  _v('locas-recuerdo', 'Cuéntale en voz alta la anécdota suya tan absurda que casi no parece cierta.', QuestionCategory.locas, Emotion.recuerdo),
  _v('locas-romance', 'Dile en voz alta la locura que harías solo para ver sonreír a tu pareja.', QuestionCategory.locas, Emotion.romance),

  // ════════════════════════════════════════════════════════════════════════
  // Retos
  // ════════════════════════════════════════════════════════════════════════
  _v('retos-futuro', 'Hazle en voz alta una promesa-reto para el próximo mes.', QuestionCategory.retos, Emotion.futuro),
  _v('retos-celebracion', 'Dile en voz alta el reto que cumplieron y que más los unió.', QuestionCategory.retos, Emotion.celebracion),
  _v('retos-recuerdo', 'Recuérdale en voz alta el reto más difícil que superaron juntos.', QuestionCategory.retos, Emotion.recuerdo),
  _v('retos-romance', 'Desafíale en voz alta a decirte algo que nunca te ha dicho.', QuestionCategory.retos, Emotion.romance),

  // ════════════════════════════════════════════════════════════════════════
  // Calientes
  // ════════════════════════════════════════════════════════════════════════
  _v('calientes-romance', 'Dile en voz baja lo que más te encendió de tu pareja esta semana.', QuestionCategory.calientes, Emotion.romance),
  _v('calientes-recuerdo', 'Recuérdale en voz baja ese momento íntimo que no olvidas.', QuestionCategory.calientes, Emotion.recuerdo),
  _v('calientes-futuro', 'Susúrrale en voz baja lo que más quieres experimentar con tu pareja.', QuestionCategory.calientes, Emotion.futuro),
  _v('calientes-celebracion', 'Dile en voz baja lo que mejor celebran cuando están a solas.', QuestionCategory.calientes, Emotion.celebracion),

  // ════════════════════════════════════════════════════════════════════════
  // Incómodas
  // ════════════════════════════════════════════════════════════════════════
  _v('incomodas-romance', 'Dile en voz alta la cosa más difícil de decirle que todavía no le has dicho.', QuestionCategory.incomodas, Emotion.romance),
  _v('incomodas-futuro', 'Cuéntale en voz alta tu mayor miedo sobre el futuro de ustedes.', QuestionCategory.incomodas, Emotion.futuro),
  _v('incomodas-recuerdo', 'Confiesa en voz alta el recuerdo de ustedes que todavía te remueve por dentro.', QuestionCategory.incomodas, Emotion.recuerdo),
  _v('incomodas-celebracion', 'Dile en voz alta qué es lo que más te costó construir en esta relación.', QuestionCategory.incomodas, Emotion.celebracion),

  // ════════════════════════════════════════════════════════════════════════
  // Extremas
  // ════════════════════════════════════════════════════════════════════════
  _v('extremas-romance', 'Dile en voz alta el compromiso más valiente que estás dispuesto a hacer por esta relación.', QuestionCategory.extremas, Emotion.romance),
  _v('extremas-futuro', 'Prométele en voz alta la conversación difícil que no quieres que vuelva a quedar pendiente.', QuestionCategory.extremas, Emotion.futuro),
  _v('extremas-recuerdo', 'Cuéntale en voz alta el momento en el que supiste que esta relación valía cualquier esfuerzo.', QuestionCategory.extremas, Emotion.recuerdo),
  _v('extremas-celebracion', 'Dile en voz alta qué es lo más profundo que han logrado construir juntos pese a todo.', QuestionCategory.extremas, Emotion.celebracion),
];

/// Constructor de momentos de voz temáticos del Momento especial.
GameQuestion _v(
  String prefix,
  String text,
  QuestionCategory category,
  Emotion emotion,
) =>
    GameQuestion(
      id: 'nue-voice-$prefix',
      text: text,
      chapter: Chapter.momentoEspecial,
      emotion: emotion,
      intensity: Intensity.intensa,
      category: category,
      type: QuestionType.voz,
      isSpecial: true,
      source: QuestionSource.original,
      status: QuestionStatus.listo,
    );
