import '../domain/enums/chapter.dart';
import '../domain/enums/emotion.dart';
import '../domain/enums/intensity.dart';
import '../domain/enums/migration.dart';
import '../domain/enums/question_category.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_question.dart';

/// Comodines de conexión del banco V1 (ids `nue-comodin-conexion-*`).
///
/// 42 preguntas tipo comodín que cambian temporalmente la dinámica de la
/// partida (acciones y momentos compartidos, no solo respuestas). Todas viven
/// en el capítulo Conexión, donde `GameChapter` ya permite `QuestionType.comodin`.
///
/// Reglas seguidas (validadas por `test/migrated_bank_test.dart`):
///  - id `nue-comodin-conexion-<emocion>-<intensidad>-<n>`;
///  - `QuestionType.comodin` (no se convierten a conversación/reto/comparación);
///  - `QuestionSource.original` y `status: listo`;
///  - capítulo `conexion`, emoción e intensidad exactas del bloque original;
///  - categoría `generales` (sin preferencia temática: en modo aleatorio la
///    escalera del selector la degrada; en modo temático solo caen en el
///    último recurso del capítulo).
final List<GameQuestion> comodinQuestionsV1 = <GameQuestion>[
  // ════════════════════════════════════════════════════════════════════════
  // 💕 Romance · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('romance-media-1', 'Mírense durante unos segundos sin hablar y después dile a tu pareja qué fue lo primero que pensaste al verla.', Emotion.romance, Intensity.media),
  _c('romance-media-2', 'Cada uno tiene 20 segundos para describir qué es lo que más le atrae del otro sin mencionar su físico.', Emotion.romance, Intensity.media),
  _c('romance-media-3', 'Tómense de la mano y cada uno diga una cosa pequeña que hace que la relación se sienta especial.', Emotion.romance, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // ❤️ Romance · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('romance-alta-1', 'Mírense a los ojos y dile a tu pareja algo que llevas tiempo queriendo decirle, pero que normalmente no dices.', Emotion.romance, Intensity.alta),
  _c('romance-alta-2', 'Cada uno complete esta frase mirando al otro: “Me enamora de ti que...”', Emotion.romance, Intensity.alta),
  _c('romance-alta-3', 'Dense un abrazo y, cuando se separen, cada uno diga qué siente que ha cambiado para bien desde que están juntos.', Emotion.romance, Intensity.alta),

  // ════════════════════════════════════════════════════════════════════════
  // 🌅 Nostalgia · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('nostalgia-media-1', 'Cada uno cuenta un momento pequeño de su relación que recuerda con una sonrisa y explica por qué se quedó en su memoria.', Emotion.nostalgia, Intensity.media),
  _c('nostalgia-media-2', 'Intenten recordar juntos su primera conversación importante. Cada uno cuenta qué recuerda de ese momento.', Emotion.nostalgia, Intensity.media),
  _c('nostalgia-media-3', 'Elijan un recuerdo que ambos tengan y cuéntenlo desde su propia perspectiva. Después comparen qué recuerda diferente cada uno.', Emotion.nostalgia, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // 🌅 Nostalgia · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('nostalgia-alta-1', 'Cada uno elige un momento de la relación que quisiera volver a vivir exactamente como ocurrió y explica por qué.', Emotion.nostalgia, Intensity.alta),
  _c('nostalgia-alta-2', 'Cierren los ojos unos segundos y recuerden uno de sus días favoritos juntos. Después cuenten qué imagen aparece primero en su mente.', Emotion.nostalgia, Intensity.alta),
  _c('nostalgia-alta-3', 'Cada uno diga qué momento de su historia juntos nunca quisiera olvidar, aunque pasaran muchos años.', Emotion.nostalgia, Intensity.alta),

  // ════════════════════════════════════════════════════════════════════════
  // 🔮 Futuro · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('futuro-media-1', 'Imaginen que dentro de un año siguen exactamente igual de unidos. ¿Qué creen que estarán haciendo juntos?', Emotion.futuro, Intensity.media),
  _c('futuro-media-2', 'Inventen entre los dos una aventura que deberían vivir juntos durante los próximos doce meses.', Emotion.futuro, Intensity.media),
  _c('futuro-media-3', 'Cada uno diga una cosa que le gustaría aprender, conocer o experimentar junto a su pareja.', Emotion.futuro, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // 🔮 Futuro · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('futuro-alta-1', 'Imaginen que se encuentran dentro de diez años. Cada uno cuenta dónde cree que estará y qué espera que siga igual entre ustedes.', Emotion.futuro, Intensity.alta),
  _c('futuro-alta-2', 'Construyan juntos una escena de su vida ideal dentro de cinco años. Cada uno debe aportar al menos tres detalles.', Emotion.futuro, Intensity.alta),
  _c('futuro-alta-3', 'Cada uno diga una promesa realista que le gustaría poder cumplir para su relación durante los próximos años.', Emotion.futuro, Intensity.alta),

  // ════════════════════════════════════════════════════════════════════════
  // 😏 Coqueteo · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('coqueteo-media-1', 'Cada uno tiene 15 segundos para convencer al otro de que es imposible resistirse a sus encantos.', Emotion.coqueteo, Intensity.media),
  _c('coqueteo-media-2', 'Dile a tu pareja algo que hace sin darse cuenta y que te parece especialmente atractivo.', Emotion.coqueteo, Intensity.media),
  _c('coqueteo-media-3', 'Cada uno inventa un apodo secreto para el otro y explica por qué lo eligió.', Emotion.coqueteo, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // 😏 Coqueteo · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('coqueteo-alta-1', 'Acérquense y díganse al oído algo que normalmente les daría pena decir en voz alta.', Emotion.coqueteo, Intensity.alta),
  _c('coqueteo-alta-2', 'Cada uno describe cuál es el momento en que su pareja le parece más irresistible.', Emotion.coqueteo, Intensity.alta),
  _c('coqueteo-alta-3', 'Durante 20 segundos, intenta hacer sonreír a tu pareja sin decir una sola palabra.', Emotion.coqueteo, Intensity.alta),

  // ════════════════════════════════════════════════════════════════════════
  // 🎉 Celebración · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('celebracion-media-1', 'Cada uno menciona algo que admira del otro y explica por qué cree que debería sentirse orgulloso de ello.', Emotion.celebracion, Intensity.media),
  _c('celebracion-media-2', 'Celebren algo pequeño que hayan conseguido juntos como si acabaran de ganar un premio.', Emotion.celebracion, Intensity.media),
  _c('celebracion-media-3', 'Cada uno cuenta una cosa que su pareja ha hecho recientemente y que le hizo pensar: “Qué suerte tengo de estar con esta persona”.', Emotion.celebracion, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // 🎉 Celebración · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('celebracion-alta-1', 'Cada uno da un pequeño discurso de 20 segundos sobre por qué está orgulloso de su relación.', Emotion.celebracion, Intensity.alta),
  _c('celebracion-alta-2', 'Imaginen que hoy es el aniversario número diez de su relación. Cada uno brinda por algo que espera que nunca pierdan.', Emotion.celebracion, Intensity.alta),
  _c('celebracion-alta-3', 'Cada uno reconoce algo que su pareja hizo por la relación y que quizá nunca recibió suficiente reconocimiento.', Emotion.celebracion, Intensity.alta),

  // ════════════════════════════════════════════════════════════════════════
  // 😂 Diversión · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('diversion-media-1', 'Inventen una regla absurda que su relación tendría que seguir durante las próximas 24 horas.', Emotion.diversion, Intensity.media),
  _c('diversion-media-2', 'Cada uno tiene 20 segundos para imitar al otro. El objetivo es que sea reconocible, pero sin burlarse.', Emotion.diversion, Intensity.media),
  _c('diversion-media-3', 'Inventen el nombre y el eslogan de una empresa que ustedes dos podrían fundar juntos.', Emotion.diversion, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // 😂 Diversión · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('diversion-alta-1', 'Inventen una situación completamente absurda en la que ustedes dos tendrían que sobrevivir juntos. Cada uno añade una regla.', Emotion.diversion, Intensity.alta),
  _c('diversion-alta-2', 'Representen durante 30 segundos cómo creen que sería una discusión entre ustedes dentro de 50 años.', Emotion.diversion, Intensity.alta),
  _c('diversion-alta-3', 'Inventen una película sobre su relación: título, género y quién interpretaría a cada uno.', Emotion.diversion, Intensity.alta),

  // ════════════════════════════════════════════════════════════════════════
  // 🤝 Conexión · Media
  // ════════════════════════════════════════════════════════════════════════
  _c('conexion-media-1', 'Cada uno diga una cosa que cree que su pareja entiende de él mejor que casi cualquier otra persona.', Emotion.conexion, Intensity.media),
  _c('conexion-media-2', 'Completen juntos esta frase: “Creo que nosotros funcionamos bien porque...”', Emotion.conexion, Intensity.media),
  _c('conexion-media-3', 'Cada uno diga una cosa que le gustaría que su pareja conociera mejor de él.', Emotion.conexion, Intensity.media),

  // ════════════════════════════════════════════════════════════════════════
  // 🤝 Conexión · Alta
  // ════════════════════════════════════════════════════════════════════════
  _c('conexion-alta-1', 'Cada uno diga algo que haya aprendido sobre el otro desde que comenzó la relación y que haya cambiado la forma en que lo ve.', Emotion.conexion, Intensity.alta),
  _c('conexion-alta-2', 'Dile a tu pareja qué parte de la relación sientes que más ha crecido desde que comenzaron.', Emotion.conexion, Intensity.alta),
  _c('conexion-alta-3', 'Cada uno complete esta frase: “Si alguna vez olvidamos por qué estamos juntos, quiero que recordemos que...”', Emotion.conexion, Intensity.alta),
];

/// Constructor de comodines: id `nue-comodin-conexion-<prefijo>`,
/// `QuestionType.comodin`, `QuestionSource.original` y `status: listo`.
GameQuestion _c(
  String prefix,
  String text,
  Emotion emotion,
  Intensity intensity,
) =>
    GameQuestion(
      id: 'nue-comodin-conexion-$prefix',
      text: text,
      chapter: Chapter.conexion,
      emotion: emotion,
      intensity: intensity,
      category: QuestionCategory.generales,
      type: QuestionType.comodin,
      source: QuestionSource.original,
      status: QuestionStatus.listo,
    );
