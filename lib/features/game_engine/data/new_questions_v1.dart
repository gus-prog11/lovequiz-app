import '../domain/enums/chapter.dart';
import '../domain/enums/emotion.dart';
import '../domain/enums/intensity.dart';
import '../domain/enums/migration.dart';
import '../domain/enums/question_category.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_question.dart';

/// Preguntas nuevas del banco V1, creadas SOLO para tapar huecos reales de
/// celdas que el motor usa y que el banco legacy no cubre.
///
/// Las celdas con cobertura insuficiente se detectaron simulando 40 partidas
/// con el motor real (`MatchBuilder` + `DefaultQuestionSelector`). Sin estas
/// preguntas, tres celdas fallaban siempre:
///
///  - `bienvenida + descubrimiento + suave` (el banco legacy solo tenía 1);
///  - `conexion + diversion` (media y alta, 1 pregunta cada una);
///  - `cierre + recuerdo + alta` (1 pregunta).
///
/// Reglas: ids `nue-*`, `QuestionSource.original`, `status` por defecto
/// `listo` y categoría `generales` (la preferencia de categoría del espacio es
/// blanda: la escalera del selector la degrada en el Nivel 3). No se crean
/// preguntas de voz nuevas (el Momento Especial queda servido por las
/// `leg-voice-*` migradas).
final List<GameQuestion> newQuestionsV1 = <GameQuestion>[
  // ════════════════════════════════════════════════════════════════════════
  // Bienvenida + Descubrimiento + suave (la celda legacy tenía 1 sola).
  // Gustos y datos ligeros que abren conversación sin profundidad.
  // ════════════════════════════════════════════════════════════════════════
  _n('bienvenida-descubrimiento-1', '¿Qué canción te pone de buen humor sí o sí?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.generales),
  _n('bienvenida-descubrimiento-2', 'Si pudieras dominar un idioma nuevo de la noche a la mañana, ¿cuál elegirías?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.generales),
  _n('bienvenida-descubrimiento-3', '¿Qué comida te hace feliz al instante?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.generales),
  _n('bienvenida-descubrimiento-4', '¿Qué película o serie volverías a ver por primera vez?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.generales),
  _n('bienvenida-descubrimiento-5', '¿Qué es lo más interesante que has aprendido últimamente?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.generales),
  _n('bienvenida-descubrimiento-6', '¿Qué lugar del mundo te llama la atención sin haberlo visitado?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.generales),

  // ════════════════════════════════════════════════════════════════════════
  // Conexión + Diversión (media y alta). Humor que ya asume complicidad.
  // ════════════════════════════════════════════════════════════════════════
  _n('conexion-diversion-1', '¿Cuál es el chiste interno que más te ha hecho reír conmigo?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.generales),
  _n('conexion-diversion-2', '¿Qué serie veríamos juntos toda la noche sin aburrirnos?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.generales),
  _n('conexion-diversion-3', 'Si tuviéramos un premio a la pareja más divertida, ¿cuál sería nuestro número de presentación?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.generales),
  _n('conexion-diversion-4', '¿Qué momento nuestro te hizo reír hasta llorar?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.generales),
  _n('conexion-diversion-5', '¿Cuál es nuestra rutina de humor improvisado que nadie más entiende?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.generales),

  // ════════════════════════════════════════════════════════════════════════
  // Cierre + Recuerdo + alta. Momentos para revivir (cierre solo admite
  // conversación/comparación, sin voz).
  // ════════════════════════════════════════════════════════════════════════
  _n('cierre-recuerdo-1', 'Si pudiéramos regresar a un solo día de nosotros y vivirlo de nuevo, ¿cuál sería?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.generales),
  _n('cierre-recuerdo-2', '¿Qué detalle nuestro quieres contarles a tus seres queridos?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.generales),
  _n('cierre-recuerdo-3', '¿Qué parte de nuestra historia merece contarse una y otra vez?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.generales),

  // ════════════════════════════════════════════════════════════════════════
  // Calentamiento + Conexión (suave y media). Sensación de equipo ligera.
  // ════════════════════════════════════════════════════════════════════════
  _n('calentamiento-conexion-1', '¿Qué es lo que mejor funciona cuando coordinamos algo juntos?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.generales),
  _n('calentamiento-conexion-2', '¿Qué rutina pequeña de nuestro día a día valoras más?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.generales),
  _n('calentamiento-conexion-3', '¿En qué momento sientes que conectamos más rápido?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.generales),
  _n('calentamiento-conexion-4', '¿Qué fue lo primero que sentimos que se nos daba bien en equipo?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.generales),
];

/// Constructor de preguntas nuevas: asigna el id `nue-<prefijo>`, marca
/// `QuestionSource.original` y por defecto `status: listo`.
GameQuestion _n(
  String prefix,
  String text,
  Chapter chapter,
  Emotion emotion,
  Intensity intensity,
  QuestionCategory category, {
  QuestionType type = QuestionType.conversacion,
  bool isSpecial = false,
  QuestionStatus status = QuestionStatus.listo,
}) =>
    GameQuestion(
      id: 'nue-$prefix',
      text: text,
      chapter: chapter,
      emotion: emotion,
      intensity: intensity,
      category: category,
      type: type,
      isSpecial: isSpecial,
      source: QuestionSource.original,
      status: status,
    );
