import '../domain/enums/chapter.dart';
import '../domain/enums/emotion.dart';
import '../domain/enums/intensity.dart';
import '../domain/enums/migration.dart';
import '../domain/enums/question_category.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_question.dart';

/// Lote temático del banco V1 (ids `nue-<categoria>-*`).
///
/// Preguntas creadas para subir la cobertura del **modo temático**: el motor
/// agota el tema elegido y solo cae a otras categorías en capítulos donde el
/// banco no tiene nada de ese tema. Estas preguntas rellenan los huecos
/// detectados en la simulación para `romanticas`, `calientes`, `divertidas`,
/// `locas`, `retos`, `incomodas` y `extremas`.
///
/// Reglas seguidas (validadas por `test/migrated_bank_test.dart`):
///  - id `nue-<categoria>-<capitulo>-<emocion>-<n>`;
///  - `QuestionSource.original` y `status: listo`;
///  - capítulo/emoción/intensidad dentro del pool y la rampa del capítulo
///    (`GameChapter.forChapter`);
///  - `type: conversacion`, salvo el bloque de `retos` que usa
///    `QuestionType.reto` (ya permitido en Bienvenida y Cierre). Las
///    `incomodas` y `extremas` "Descubrimiento · alta" se reclasifican a
///    Calentamiento + media, la celda válida más cercana.
final List<GameQuestion> thematicQuestionsV1 = <GameQuestion>[
  // ════════════════════════════════════════════════════════════════════════
  // ROMÁNTICAS
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Diversión · suave
  _n('romanticas-bienvenida-diversion-1', '¿Qué cosa romántica te parecería demasiado cursi para hacerla en público, pero divertida en privado?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-bienvenida-diversion-2', 'Si tuvieras que organizar nuestra cita perfecta con solo 500 pesos, ¿qué haríamos?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-bienvenida-diversion-3', '¿Qué detalle pequeño podría convertir una tarde normal en una buena cita?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.romanticas),
  // Bienvenida · Descubrimiento · suave
  _n('romanticas-bienvenida-descubrimiento-1', '¿Qué tipo de cita siempre has querido probar aunque nunca hayas tenido la oportunidad?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-bienvenida-descubrimiento-2', '¿Qué detalle hace que una persona te parezca especialmente atractiva sin que tenga que ver con su físico?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.romanticas),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('romanticas-calentamiento-descubrimiento-1', '¿Qué fue lo primero que te llamó la atención de mí cuando nos conocimos?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-descubrimiento-2', '¿Qué cosa de tu forma de demostrar cariño crees que todavía estoy descubriendo?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.romanticas),
  // Calentamiento · Diversión · suave
  _n('romanticas-calentamiento-diversion-1', 'Si nuestra relación tuviera una regla completamente absurda, ¿cuál sería?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-diversion-2', '¿Qué apodo ridículo crees que nos quedaría como pareja?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-diversion-3', 'Si tuvieras que describir nuestra relación usando solo tres emojis, ¿cuáles elegirías?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.romanticas),
  // Calentamiento · Diversión · media
  _n('romanticas-calentamiento-diversion-4', 'Si mañana tuviéramos todo el día libre y no pudiéramos gastar dinero, ¿qué aventura inventaríamos?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-diversion-5', '¿Qué situación completamente absurda crees que nos haría reír durante años?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-diversion-6', 'Si intercambiáramos personalidades durante un día, ¿qué sería lo primero que harías siendo yo?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.romanticas),
  // Calentamiento · Nostalgia · suave
  _n('romanticas-calentamiento-nostalgia-1', '¿Qué recuerdas de uno de nuestros primeros momentos que todavía te hace sonreír?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-nostalgia-2', '¿Cuál fue una de las primeras cosas que hicimos juntos que te gustaría repetir?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.romanticas),
  // Calentamiento · Nostalgia · media
  _n('romanticas-calentamiento-nostalgia-3', '¿Qué instante nuestro te gustaría poder volver a mirar desde afuera como una película?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-nostalgia-4', '¿Qué recuerdo nuestro sientes que representa muy bien cómo somos juntos?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-nostalgia-5', '¿Qué momento que parecía pequeño en ese entonces terminó convirtiéndose en un recuerdo importante para ti?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.romanticas),
  // Calentamiento · Conexión · suave
  _n('romanticas-calentamiento-conexion-1', '¿Qué cosa hacemos juntos que te hace sentir que simplemente podemos ser nosotros?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-conexion-2', '¿En qué momentos sientes que hacemos buen equipo?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-conexion-3', '¿Qué pequeño gesto mío te hace sentir acompañado/a?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.romanticas),
  // Calentamiento · Conexión · media
  _n('romanticas-calentamiento-conexion-4', '¿Qué parte de nuestra relación sientes que ha cambiado para mejor desde que empezamos?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-conexion-5', '¿Qué crees que hacemos diferente cuando estamos juntos que no hacemos con otras personas?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-calentamiento-conexion-6', '¿Qué es algo que te gustaría que nunca perdiéramos aunque nuestra relación cambie con los años?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.romanticas),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Romance · alta
  _n('romanticas-conexion-romance-1', '¿Qué parte de nuestra relación te hace sentir más querido/a?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-romance-2', '¿Qué es algo que hago por ti que quizá no sé cuánto significa para ti?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-romance-3', 'Si tuvieras que explicar qué hace especial nuestra relación, ¿qué dirías?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas),
  // Conexión · Nostalgia · alta
  _n('romanticas-conexion-nostalgia-1', '¿Qué momento de nuestra historia cambiarías por nada del mundo?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-nostalgia-2', '¿Qué canción sería la banda sonora del recuerdo que más conservas de nosotros?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-nostalgia-3', '¿Cuál ha sido el momento en el que más has sentido que nuestra historia realmente empezó a convertirse en "nosotros"?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas),
  // Conexión · Coqueteo · media
  _n('romanticas-conexion-coqueteo-1', '¿Qué cosa hago que sabes que me hace irresistible para ti?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-conexion-coqueteo-2', '¿Cuál crees que es mi arma secreta cuando quiero conquistarte?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.romanticas),
  // Conexión · Coqueteo · alta
  _n('romanticas-conexion-coqueteo-3', '¿Qué momento entre nosotros ha tenido la mayor tensión romántica?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-coqueteo-4', '¿Qué parte de mi personalidad te resulta más difícil resistir?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-coqueteo-5', 'Si tuvieras que volver a conquistarme desde cero, ¿cómo lo intentarías?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas),
  // Conexión · Celebración · media
  _n('romanticas-conexion-celebracion-1', '¿Qué logro cotidiano de nosotros dos merecería más celebración de la que le damos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-conexion-celebracion-2', 'Si hoy tuviéramos que brindar por un detalle pequeño de nuestra rutina, ¿por cuál brindaríamos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-conexion-celebracion-3', '¿Qué cualidad nuestra como pareja te gustaría que otras parejas pudieran aprender de nosotros?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas),
  // Conexión · Celebración · alta
  _n('romanticas-conexion-celebracion-4', '¿Qué es lo que más orgulloso/a te hace sentir de nuestra relación?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-celebracion-5', '¿Qué hemos superado juntos que hoy te hace valorar más lo que tenemos?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-celebracion-6', 'Si tuvieras que brindar por una sola cosa que hemos construido juntos, ¿por qué brindarías?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas),
  // Conexión · Diversión · media
  _n('romanticas-conexion-diversion-1', 'Si nuestra relación fuera una película romántica, ¿qué escena sería inevitable?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-conexion-diversion-2', '¿Qué cosa completamente ridícula hacemos como pareja y secretamente te encanta?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas),
  _n('romanticas-conexion-diversion-3', 'Si pudiéramos repetir una cita nuestra pero obligándonos a hacerla diez veces más divertida, ¿cuál elegirías?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas),
  // Conexión · Diversión · alta
  _n('romanticas-conexion-diversion-4', 'Si mañana nos despertáramos en otro país sin equipaje, ¿qué haríamos para que siga sintiéndose como una cita nuestra?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-diversion-5', 'Si tuvieras que inventar una tradición absurda que solo nosotros dos pudiéramos entender, ¿cuál sería?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-diversion-6', '¿Qué locura inofensiva crees que deberíamos hacer juntos al menos una vez?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.romanticas),
  // Conexión · Conexión · alta
  _n('romanticas-conexion-conexion-1', '¿Qué costumbre tuya has adoptado desde que estamos juntos sin darte cuenta?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-conexion-2', '¿Qué parte de mí sientes que puedes entender mejor que casi cualquier otra persona?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-conexion-conexion-3', '¿Qué es algo de nuestra relación que te gustaría proteger siempre, sin importar cuánto cambien nuestras vidas?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.romanticas),
  // Conexión · Comparación · media (ambos eligen, luego se comparan)
  _n('romanticas-conexion-romance-4', '¿Quién de los dos dijo primero "te quiero"?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo lo dije primero', 'Lo dijiste tú primero']),
  _n('romanticas-conexion-coqueteo-6', '¿Quién inicia casi siempre los planes de cita?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Casi siempre yo', 'Casi siempre tú']),
  _n('romanticas-conexion-diversion-7', '¿Quién es más cursi en el trato diario?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo soy más cursi', 'Tú eres más cursi']),
  _n('romanticas-conexion-celebracion-7', '¿Quién recuerda mejor los aniversarios y fechas importantes?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo recuerdo mejor', 'Tú recuerdas mejor']),
  _n('romanticas-conexion-futuro-1', '¿Quién de los dos sueña más con el futuro juntos?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo sueño más', 'Tú sueñas más']),
  // Conexión · Comparación · alta
  _n('romanticas-conexion-romance-5', 'Si fuera nuestro último día juntos, ¿quién lo llevaría peor?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo lo llevaría peor', 'Tú lo llevarías peor']),
  _n('romanticas-conexion-nostalgia-4', '¿Quién de los dos guarda más recuerdos (fotos, entradas, mensajes)?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo guardo más', 'Tú guardas más']),
  _n('romanticas-conexion-coqueteo-7', '¿Quién pone más "chispa" cuando las cosas se vuelven rutina?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo pongo la chispa', 'Tú pones la chispa']),
  _n('romanticas-conexion-futuro-2', '¿Quién propone primero los planes a largo plazo?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas, type: QuestionType.comparacion, options: ['Yo propongo primero', 'Tú propones primero']),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Celebración · alta
  _n('romanticas-cierre-celebracion-1', '¿Qué es algo de nosotros que hoy te hace pensar: "Qué bueno que nos encontramos"?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-cierre-celebracion-2', '¿Qué momento de nuestra historia merece que algún día lo celebremos aunque hayan pasado muchos años?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas),
  // Cierre · Futuro · alta
  _n('romanticas-cierre-futuro-1', '¿Qué experiencia te gustaría que algún día recordemos diciendo: "¿Te acuerdas cuando decidimos hacer esto?"?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas),
  _n('romanticas-cierre-futuro-2', 'Si pudiéramos agregar un nuevo capítulo a nuestra historia este año, ¿qué te gustaría que ocurriera?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas),
  // Cierre · Recuerdo · alta
  _n('romanticas-cierre-recuerdo-1', 'Si pudieras guardar una sola sensación de nuestra relación para volver a sentirla dentro de muchos años, ¿cuál elegirías?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.romanticas),

  // ════════════════════════════════════════════════════════════════════════
  // CALIENTES
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Diversión · suave
  _n('calientes-bienvenida-diversion-1', '¿Qué cosa de mí te parece más divertida cuando intento coquetear contigo?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-bienvenida-diversion-2', 'Si tuvieras que inventarme un apodo secreto para cuando estamos coqueteando, ¿cuál sería?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-bienvenida-diversion-3', '¿Qué situación completamente inesperada podría terminar convirtiéndose en una cita muy coqueta entre nosotros?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.calientes),
  // Bienvenida · Descubrimiento · suave
  _n('calientes-bienvenida-descubrimiento-1', '¿Qué detalle de una persona puede hacer que empieces a verla de una manera diferente?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-bienvenida-descubrimiento-2', '¿Qué tipo de mirada te parece más difícil de ignorar?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-bienvenida-descubrimiento-3', '¿Qué pequeño gesto puede hacer que alguien te parezca especialmente atractivo?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.calientes),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('calientes-calentamiento-descubrimiento-1', '¿Qué fue lo primero que te pareció atractivo de mí?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-descubrimiento-2', '¿Qué detalle físico mío crees que notaste antes de que yo me diera cuenta?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-descubrimiento-3', '¿Qué tipo de personalidad te resulta más atractiva?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.calientes),
  // Calentamiento · Descubrimiento · media
  _n('calientes-calentamiento-descubrimiento-4', '¿Qué cosa de mí te parece más atractiva ahora que me conoces mejor?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-descubrimiento-5', '¿Qué gesto mío cambia completamente la forma en que me ves?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-descubrimiento-6', '¿Qué tipo de actitud hace que alguien pase de parecerte interesante a parecerte irresistible?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.calientes),
  // Calentamiento · Diversión · suave
  _n('calientes-calentamiento-diversion-1', 'Si tuvieras que calificar mi forma de coquetear del 1 al 10, ¿qué nota me pondrías?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-diversion-2', '¿Qué señal te delata cuando estás coqueteando sin darte cuenta?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-diversion-3', 'Si nuestra relación tuviera una regla secreta para momentos de coqueteo, ¿cuál sería?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.calientes),
  // Calentamiento · Diversión · media
  _n('calientes-calentamiento-diversion-4', 'Si tuvieras que intentar conquistarme usando solamente tres frases, ¿cuáles usarías?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-diversion-5', 'Hazle un concurso de miradas ahora mismo; el primero en reírse pierde. ¿Quién ganó?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-diversion-6', 'Si estuviéramos en una cita y tuvieras que hacerme sonrojar sin tocarme, ¿qué harías?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.calientes),
  // Calentamiento · Nostalgia · suave
  _n('calientes-calentamiento-nostalgia-1', '¿Recuerdas algún momento en el que empezaste a verme de una manera diferente?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-nostalgia-2', '¿Recuerdas el primer momento en que sentiste algo por mí?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-nostalgia-3', '¿Qué recuerdo de nuestros comienzos todavía te provoca una sonrisa?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.calientes),
  // Calentamiento · Nostalgia · media
  _n('calientes-calentamiento-nostalgia-4', '¿Qué momento entre nosotros recuerdas como especialmente intenso, aunque en ese momento no lo dijéramos?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-nostalgia-5', '¿Cuándo recuerdas haber sentido por primera vez que entre nosotros había una atracción especial?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-nostalgia-6', '¿Qué anécdota nuestra repetirías mil veces sin cansarte?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes),
  // Calentamiento · Conexión · suave
  _n('calientes-calentamiento-conexion-1', '¿Qué hago que te hace sentir especialmente deseado/a?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-conexion-2', '¿Qué tipo de atención mía disfrutas más?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.calientes),
  _n('calientes-calentamiento-conexion-3', '¿Qué momento cotidiano entre nosotros puede convertirse fácilmente en un momento especial?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.calientes),
  // Calentamiento · Conexión · media
  _n('calientes-calentamiento-conexion-4', '¿Qué hago que te hace sentir más cerca de mí cuando estamos solos?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-conexion-5', '¿Qué gesto físico te hace sentir en sintonía conmigo?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-calentamiento-conexion-6', '¿Qué crees que hace que nuestra química funcione?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.calientes),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Romance · media
  _n('calientes-conexion-romance-1', 'Si tuvieras que describir el momento romántico más especial de nosotros con una sola palabra, ¿cuál sería?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-romance-2', '¿Qué detalle mío puede hacer que una noche normal se sienta como una cita?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-romance-3', '¿Qué tipo de momento entre nosotros hace que vuelvas a sentir esa emoción de cuando empezábamos?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes),
  // Conexión · Romance · alta
  _n('calientes-conexion-romance-4', '¿Cuál ha sido uno de esos momentos conmigo en los que sentiste una conexión especialmente intensa?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-romance-5', '¿Qué parte de nuestra intimidad sientes que nos hace únicos?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-romance-6', '¿Qué momento romántico te gustaría que volviéramos a vivir, pero esta vez haciéndolo todavía más especial?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Nostalgia · media
  _n('calientes-conexion-nostalgia-1', '¿Qué recuerdo nuestro te hace volver inmediatamente a la sensación que tenías en ese momento?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-nostalgia-2', '¿Cuándo notaste por primera vez que entre nosotros había química?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-nostalgia-3', '¿Qué olor, canción o lugar te trae de vuelta un momento nuestro sin avisarte?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes),
  // Conexión · Nostalgia · alta
  _n('calientes-conexion-nostalgia-4', '¿Qué momento entre nosotros recuerdas con más intensidad?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-nostalgia-5', '¿Qué recuerdo nuestro cambió la forma en que me miras?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-nostalgia-6', 'Si pudieras volver durante unos minutos a uno de nuestros momentos más intensos, ¿cuál elegirías?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Futuro · media
  _n('calientes-conexion-futuro-1', '¿Cuál crees que sería más divertido: una cita sorpresa a ciegas o un karaoke privado? ¿Por qué?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-futuro-2', '¿Qué lugar te parecería perfecto para una escapada romántica solo nosotros dos?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-futuro-3', '¿Qué experiencia nueva te gustaría descubrir conmigo?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes),
  // Conexión · Futuro · alta
  _n('calientes-conexion-futuro-4', '¿Qué tipo de noche juntos te gustaría recordar durante muchos años?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-futuro-5', '¿Qué promesa romántica nos haríamos para el próximo aniversario?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-futuro-6', 'Si pudiéramos desaparecer juntos durante un fin de semana sin preocuparnos por nada, ¿cómo sería?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Coqueteo · alta
  _n('calientes-conexion-coqueteo-1', '¿Qué hago que sabes perfectamente que me queda demasiado bien?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-coqueteo-2', '¿Cuál es la forma más fácil que tienes de hacerme perder la concentración?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-coqueteo-3', 'Si quisieras provocarme una sonrisa sin decir una sola palabra, ¿qué harías?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Celebración · media
  _n('calientes-conexion-celebracion-1', '¿Qué hace especialmente bien nuestra química cuando se enciende?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-celebracion-2', '¿Qué cosa de nuestra química crees que no podríamos replicar con nadie más?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-celebracion-3', '¿Cuál es la señal de que la química está a punto de encenderse entre nosotros?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes),
  // Conexión · Celebración · alta
  _n('calientes-conexion-celebracion-4', '¿Qué momento de nosotros solos celebrarías aunque nadie más esté mirando?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-coqueteo-6', '¿Qué hago que te hace sentir deseado/a incluso sin decir una palabra?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-celebracion-6', '¿Qué momento entre nosotros te hizo pensar: "definitivamente tenemos química"?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Diversión · media
  _n('calientes-conexion-diversion-1', 'Si nuestra química tuviera una canción, ¿cuál sería?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-diversion-2', 'Cuéntale cuál es tu provocación favorita para llamar su atención.', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-diversion-3', 'Si tuvieras que inventar una cita diseñada específicamente para hacerme perder la compostura, ¿cómo sería?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes),
  // Conexión · Diversión · alta
  _n('calientes-conexion-diversion-4', '¿Qué harías si tuvieras exactamente un minuto para hacerme sonrojar?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-diversion-5', '¿Qué gesto mío te pone en modo coqueto sin avisarte?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-diversion-6', 'Si no pudiéramos decirnos directamente lo que queremos y solo pudiéramos insinuarlo, ¿quién ganaría?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Conexión · media
  _n('calientes-conexion-conexion-1', '¿Qué momento de cercanía física sientes que nos conecta de verdad?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-conexion-2', '¿Qué momento del día disfrutas más cuando estamos juntos y podemos estar solos?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.calientes),
  _n('calientes-conexion-conexion-3', '¿Qué crees que hace diferente nuestra forma de acercarnos el uno al otro?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.calientes),
  // Conexión · Conexión · alta
  _n('calientes-conexion-conexion-4', '¿Qué momento entre nosotros te hace sentir que desaparece todo lo demás?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-conexion-5', '¿Qué parte de nuestra conexión sientes que solo nosotros entendemos?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-conexion-conexion-6', '¿Qué tipo de momento entre nosotros hace que te cueste pensar en cualquier otra cosa?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.calientes),
  // Conexión · Comparación · media (ambos eligen, luego se comparan)
  _n('calientes-conexion-romance-7', '¿Quién de los dos prefiere la intimidad tranquila o la apasionada?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo prefiero la tranquila', 'Yo prefiero la apasionada']),
  _n('calientes-conexion-coqueteo-4', '¿Quién de los dos tarda más en "entrar en clima"?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo tardo más', 'Tú tardas más']),
  _n('calientes-conexion-diversion-7', '¿Quién de los dos suele proponer las cosas más atrevidas?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Casi siempre yo', 'Casi siempre tú']),
  _n('calientes-conexion-futuro-7', '¿Quién de los dos está más pendiente de que haya "fecha especial"?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo estoy más pendiente', 'Tú estás más pendiente']),
  _n('calientes-conexion-celebracion-7', '¿Quién de los dos pone la "música adecuada" en los momentos importantes?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo elijo mejor', 'Tú eliges mejor']),
  // Conexión · Comparación · alta
  _n('calientes-conexion-nostalgia-7', '¿Quién de los dos habla más de lo bien que estuvo el primer beso?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo hablo más', 'Tú hablas más']),
  _n('calientes-conexion-coqueteo-5', '¿Quién de los dos aguanta más sin buscar el contacto?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo aguanto más', 'Tú aguantas más']),
  _n('calientes-conexion-romance-8', '¿Quién de los dos necesita más tiempo a solas después de un momento intenso?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo necesito más tiempo', 'Tú necesitas más tiempo']),
  _n('calientes-conexion-futuro-8', '¿Quién de los dos planificaría mejor una escapada sorpresa?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes, type: QuestionType.comparacion, options: ['Yo planifico mejor', 'Tú planificas mejor']),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Romance · alta
  _n('calientes-cierre-romance-1', '¿Qué parte de nuestra relación te sigue haciendo sentir esa emoción que sentiste al principio?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-romance-2', '¿Qué momento conmigo te gustaría que nunca dejara de sentirse especial?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-romance-3', 'Si tuvieras que elegir una sola cosa de nuestra relación para conservar siempre, ¿qué sería?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.calientes),
  // Cierre · Nostalgia · alta
  _n('calientes-cierre-nostalgia-1', '¿Qué momento de nuestra historia todavía puede hacerte sentir exactamente como aquella vez?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-nostalgia-2', '¿Cuál de nuestros recuerdos tiene más química cuando vuelves a pensarlo?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-nostalgia-3', 'Si esta noche fuera el capítulo final de una serie sobre nosotros, ¿cómo cerraría la última escena?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes),
  // Cierre · Celebración · alta
  _n('calientes-cierre-celebracion-1', '¿Qué logro de nosotros dos merece celebrarse con la química que ya tenemos?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-celebracion-2', '¿Qué hemos construido juntos de lo que hoy sí podemos sentirnos orgullosos?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes),
  // Cierre · Futuro · alta
  _n('calientes-cierre-futuro-1', '¿Qué experiencia entre nosotros todavía nos falta vivir y te emociona imaginar?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-futuro-2', '¿Qué momento nos queda por vivir que quieras contar como anécdota?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.calientes),
  // Cierre · Recuerdo · alta
  _n('calientes-cierre-recuerdo-1', '¿Qué momento de esta partida te gustaría recordar cuando volvamos a estar juntos?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.calientes),
  _n('calientes-cierre-recuerdo-2', 'Si tuvieras que guardar una sola sensación de esta noche, ¿cuál elegirías?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.calientes),

  // ════════════════════════════════════════════════════════════════════════
  // DIVERTIDAS
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Descubrimiento · suave
  _n('divertidas-bienvenida-descubrimiento-1', '¿Qué cosa pequeña de tu personalidad crees que me sorprendería descubrir?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.divertidas),
  _n('divertidas-bienvenida-descubrimiento-2', '¿Qué gusto tuyo crees que casi nadie imaginaría al conocerte?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.divertidas),
  _n('divertidas-bienvenida-descubrimiento-3', '¿Qué cosa haces de una manera tan particular que probablemente solo yo terminaría notando?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.divertidas),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('divertidas-calentamiento-descubrimiento-1', '¿Qué cosa extraña o curiosa te gusta que probablemente no sé?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.divertidas),
  _n('divertidas-calentamiento-descubrimiento-2', '¿Qué hábito tuyo crees que me parecería más gracioso si viviera contigo?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.divertidas),
  // Calentamiento · Descubrimiento · media
  _n('divertidas-calentamiento-descubrimiento-3', '¿Qué causa o teoría ridícula defenderías con todo el corazón aunque nadie te crea?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.divertidas),
  // Calentamiento · Diversión · suave
  _n('divertidas-calentamiento-diversion-1', 'Si nuestra pareja tuviera un lema completamente ridículo, ¿cuál sería?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.divertidas),
  // Calentamiento · Nostalgia · suave
  _n('divertidas-calentamiento-nostalgia-1', '¿Qué tontería de cuando éramos más pequeños todavía te hace reír cuando la recuerdas?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.divertidas),
  _n('divertidas-calentamiento-nostalgia-2', '¿Qué momento divertido de nuestra relación te gustaría volver a vivir?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.divertidas),
  // Calentamiento · Nostalgia · media
  _n('divertidas-calentamiento-nostalgia-3', '¿Cuál ha sido nuestra situación más absurda que ahora podemos recordar y reírnos de ella?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas),
  // Calentamiento · Conexión · suave
  _n('divertidas-calentamiento-conexion-1', '¿Qué cosa hacemos juntos que siempre termina haciéndonos reír?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.divertidas),
  _n('divertidas-calentamiento-conexion-2', '¿Qué crees que es lo más divertido de nuestra forma de ser como pareja?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.divertidas),
  _n('divertidas-calentamiento-conexion-3', '¿Qué pequeña costumbre nuestra te gustaría que nunca perdiéramos?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.divertidas),
  // Calentamiento · Conexión · media
  _n('divertidas-calentamiento-conexion-4', '¿Qué disparate de los nuestros acabó siendo un recuerdo que vale oro?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-calentamiento-conexion-5', '¿Qué cosa tonta hacemos juntos sin darnos cuenta y que nos hace reír?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-calentamiento-conexion-6', '¿Cuál dirías que es nuestra habilidad secreta para pasarla bien juntos?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.divertidas),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Romance · media
  _n('divertidas-conexion-romance-1', 'Si nuestra historia fuera una comedia romántica, ¿qué escena tendría que aparecer sí o sí?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-romance-2', '¿Qué situación romántica completamente inesperada crees que terminaría siendo muy nosotros?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-romance-3', '¿Qué detalle romántico podría hacerte reír y sentir querido/a al mismo tiempo?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Romance · alta
  _n('divertidas-conexion-romance-4', 'Si tuvieras que preparar una cita perfecta para mí pero con un elemento completamente absurdo, ¿qué harías?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-romance-5', '¿Qué momento romántico entre nosotros crees que sería todavía mejor si pudiéramos repetirlo con cero vergüenza?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-romance-6', 'Si mañana pudiéramos vivir una escena digna de una película romántica, ¿qué te gustaría que ocurriera?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.divertidas),
  // Conexión · Nostalgia · media
  _n('divertidas-conexion-nostalgia-1', '¿Cuál de nuestras anécdotas crees que vamos a seguir contando dentro de diez años?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-nostalgia-2', '¿Qué recuerdo nuestro empezó siendo una tontería y terminó convirtiéndose en uno de tus favoritos?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-nostalgia-3', 'Cuenta nuestra historia como la sinopsis de una comedia: ¿qué título le pondrías?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Nostalgia · alta
  _n('divertidas-conexion-nostalgia-4', '¿Qué momento nuestro fue tan absurdo que, si alguien lo hubiera grabado, todavía lo veríamos juntos?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-nostalgia-5', '¿Cuál ha sido nuestra aventura más caótica que terminó saliendo bien?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-nostalgia-6', 'Si pudieras volver a uno de nuestros momentos más divertidos y cambiar una sola cosa para hacerlo todavía más absurdo, ¿qué cambiarías?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas),
  // Conexión · Futuro · media
  _n('divertidas-conexion-futuro-1', '¿Qué cosa absurda deberíamos hacer juntos al menos una vez en los próximos años?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-futuro-2', 'Si dentro de cinco años seguimos teniendo el mismo sentido del humor, ¿de qué crees que nos estaremos riendo?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-futuro-3', '¿Qué tradición extraña te gustaría que inventáramos como pareja?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Futuro · alta
  _n('divertidas-conexion-futuro-4', 'Si pudiéramos planear una aventura completamente fuera de lo normal para nosotros, ¿qué haríamos?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-futuro-5', '¿Qué locura inofensiva te gustaría poder contar algún día diciendo: "Lo hicimos juntos"?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-futuro-6', 'Si tuviéramos un mes entero para hacer cosas que normalmente no haríamos, ¿qué sería lo primero que intentaríamos?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas),
  // Conexión · Coqueteo · media
  _n('divertidas-conexion-coqueteo-1', 'Pruébalo ahora: di algo que consiga sonrojarlo de verdad. ¿Qué frase usaste?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-coqueteo-2', '¿Qué hago cuando intento coquetear contigo que te parece más divertido que efectivo?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-coqueteo-3', 'Si tuvieras que coquetearme de la forma más ridícula posible, ¿cuál sería?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Coqueteo · alta
  _n('divertidas-conexion-coqueteo-4', 'Si tuvieras que hacerme perder la concentración sin tocarme, ¿qué harías?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-coqueteo-5', '¿Qué truco de seducción crees que me falla con vos y yo no me entero?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-coqueteo-6', 'Si tuviéramos un concurso para ver quién consigue hacer sonrojar primero al otro, ¿cómo intentarías ganar?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.divertidas),
  // Conexión · Celebración · media
  _n('divertidas-conexion-celebracion-1', '¿Qué cosa hacemos como pareja que merece una medalla completamente innecesaria?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-celebracion-2', 'Si existiera un premio para nuestra relación, ¿qué categoría ganaríamos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-celebracion-3', '¿Qué victoria tonta de la semana pasada deberíamos celebrar con un baile?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Celebración · alta
  _n('divertidas-conexion-celebracion-4', 'Si tuvieras que inventar un premio que describiera nuestra relación, ¿qué nombre tendría?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-celebracion-5', '¿Qué logro nuestro merece una fiesta tan exagerada que se vuelva su propia anécdota?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-celebracion-6', '¿Qué cosa hemos conseguido juntos que probablemente nosotros mismos no valoramos lo suficiente?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas),
  // Conexión · Diversión · media
  _n('divertidas-conexion-diversion-1', 'Si nos encerraran durante 24 horas en un lugar lleno de juegos, ¿cuál sería el primero que intentarías ganar?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-diversion-2', 'Si tuvieras que elegir una competencia absurda para descubrir quién de los dos es mejor, ¿cuál sería?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-diversion-3', '¿Qué reto completamente ridículo crees que aceptaríamos solamente por diversión?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Diversión · alta
  _n('divertidas-conexion-diversion-4', 'Si tuviéramos una hora libre solo para tontear sin que nada importe, ¿qué haríamos?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-diversion-5', 'Si tuvieras que inventar el día más absurdo posible para nosotros, ¿qué tendría que pasar?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-diversion-6', '¿Qué sería más divertido: intercambiar vidas durante un día o intercambiar personalidades durante una semana? ¿Por qué?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.divertidas),
  // Conexión · Conexión · media
  _n('divertidas-conexion-conexion-1', '¿Qué cosa de nuestra personalidad juntos crees que hace que nunca nos aburramos completamente?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-conexion-2', '¿Qué situación demuestra mejor que hacemos buen equipo incluso cuando todo sale mal?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.divertidas),
  _n('divertidas-conexion-conexion-3', '¿Qué tontería nuestra te hace pensar: "Con esta persona sí puedo ser yo"?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.divertidas),
  // Conexión · Conexión · alta
  _n('divertidas-conexion-conexion-4', 'Si tuvieras que explicar nuestro sentido del humor a alguien que nunca nos ha visto juntos, ¿cómo lo describirías?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-conexion-5', '¿Qué momento en el que nos reímos juntos te hizo sentir especialmente conectado/a conmigo?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-conexion-conexion-6', '¿Qué parte de nuestra forma de divertirnos juntos crees que sería difícil de explicar a alguien que no nos conoce?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.divertidas),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Romance · alta
  _n('divertidas-cierre-romance-1', '¿Qué momento divertido y romántico de nosotros te gustaría repetir pronto?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-romance-2', '¿Qué cosa de nuestra relación consigue hacerte sentir querido/a incluso cuando estamos haciendo tonterías?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-romance-3', 'Si tuvieras que terminar esta partida con una cita perfecta para nosotros, ¿cómo sería?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.divertidas),
  // Cierre · Nostalgia · alta
  _n('divertidas-cierre-nostalgia-1', '¿Qué momento de esta partida crees que algún día nos dará risa recordar?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-nostalgia-2', '¿Qué momento divertido de nosotros merece una foto que enmarquemos en la sala?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-nostalgia-3', 'Si tuviéramos que elegir una sola anécdota nuestra para contarle a alguien dentro de diez años, ¿cuál sería?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas),
  // Cierre · Celebración · alta
  _n('divertidas-cierre-celebracion-1', '¿Qué fue lo más divertido que descubriste o recordaste de nosotros durante esta partida?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-celebracion-2', '¿Qué momento de nuestra relación merece que hoy brindemos por él?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-celebracion-3', 'Si pudiéramos celebrar nuestra relación ahora mismo de la forma más absurda posible, ¿qué haríamos?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas),
  // Cierre · Futuro · alta
  _n('divertidas-cierre-futuro-1', '¿Qué aventura divertida deberíamos asegurarnos de vivir juntos algún día?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas),
  _n('divertidas-cierre-futuro-2', '¿Qué cosa te gustaría que pudiéramos mirar dentro de unos años y decir: "Qué bueno que hicimos eso"?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas),
  // Cierre · Recuerdo · alta
  _n('divertidas-cierre-recuerdo-1', 'Si pudieras guardar un solo momento divertido de nosotros para volver a verlo dentro de muchos años, ¿cuál guardarías?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.divertidas),

  // ════════════════════════════════════════════════════════════════════════
  // LOCAS
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Diversión · suave
  _n('locas-bienvenida-diversion-1', 'Si mañana despertáramos con una habilidad completamente inútil, ¿cuál te gustaría que tuviéramos?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.locas),
  _n('locas-bienvenida-diversion-2', 'Si nuestra pareja tuviera que sobrevivir un día siguiendo una regla absurda, ¿qué regla elegirías?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.locas),
  _n('locas-bienvenida-diversion-3', '¿Qué cosa completamente ridícula crees que podríamos convertir en una tradición nuestra?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.locas),
  // Bienvenida · Descubrimiento · suave
  _n('locas-bienvenida-descubrimiento-1', '¿Qué decisión absurda crees que tomarías sin pensarlo demasiado?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.locas),
  _n('locas-bienvenida-descubrimiento-2', '¿Qué cosa rara te gustaría probar alguna vez solo por saber qué se siente?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.locas),
  _n('locas-bienvenida-descubrimiento-3', '¿Qué opinión extraña tienes que probablemente no mucha gente comparte contigo?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.locas),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('locas-calentamiento-descubrimiento-1', '¿Qué cosa extraña siempre te ha dado curiosidad?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.locas),
  _n('locas-calentamiento-descubrimiento-2', '¿Qué actividad rara crees que disfrutarías aunque nunca la hayas probado?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.locas),
  _n('locas-calentamiento-descubrimiento-3', '¿Qué cosa completamente inesperada crees que se te daría muy bien?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.locas),
  // Calentamiento · Descubrimiento · media
  _n('locas-calentamiento-descubrimiento-4', '¿Qué experiencia fuera de lo común te gustaría vivir al menos una vez?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.locas),
  _n('locas-calentamiento-descubrimiento-5', '¿Qué harías si durante un día nadie pudiera juzgar ninguna decisión tuya?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.locas),
  _n('locas-calentamiento-descubrimiento-6', '¿Qué parte de tu personalidad crees que aparece solamente cuando estás haciendo algo completamente fuera de lo normal?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.locas),
  // Calentamiento · Diversión · suave
  _n('locas-calentamiento-diversion-1', 'Si tuvieras que inventar un deporte absurdo para que nosotros compitiéramos, ¿cómo funcionaría?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.locas),
  // Calentamiento · Nostalgia · suave
  _n('locas-calentamiento-nostalgia-1', '¿Qué cosa absurda hacías de pequeño/a que ahora te da risa recordar?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.locas),
  _n('locas-calentamiento-nostalgia-2', '¿Cuál es una de las situaciones más ridículas que recuerdas haber vivido?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.locas),
  _n('locas-calentamiento-nostalgia-3', '¿Qué travesura de tu infancia repetirías solamente para volver a reírte?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.locas),
  // Calentamiento · Nostalgia · media
  _n('locas-calentamiento-nostalgia-4', '¿Cuál ha sido la situación más inesperada que hemos vivido juntos?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.locas),
  _n('locas-calentamiento-nostalgia-5', '¿Qué momento nuestro empezó completamente normal y terminó siendo una locura?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.locas),
  _n('locas-calentamiento-nostalgia-6', '¿Cuál es nuestra anécdota más difícil de explicar sin que parezca inventada?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.locas),
  // Calentamiento · Conexión · suave
  _n('locas-calentamiento-conexion-1', '¿Qué cosa rara crees que tenemos en común?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.locas),
  _n('locas-calentamiento-conexion-2', '¿Qué tontería hacemos juntos que probablemente nadie más entendería?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.locas),
  _n('locas-calentamiento-conexion-3', '¿Qué ocurrencia nuestra termina casi siempre en un buen recuerdo?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.locas),
  // Calentamiento · Conexión · media
  _n('locas-calentamiento-conexion-4', 'Si tuvieras que describir nuestra relación usando una situación completamente absurda, ¿cuál sería?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.locas),
  _n('locas-calentamiento-conexion-5', '¿Qué cosa inesperada crees que hace que nosotros funcionemos tan bien juntos?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.locas),
  _n('locas-calentamiento-conexion-6', 'Si nos conociéramos en una situación completamente diferente a la actual, ¿qué crees que haría que termináramos llevándonos bien?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.locas),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Romance · media
  _n('locas-conexion-romance-1', 'Si pudiéramos tener una cita en cualquier lugar del mundo aunque fuera completamente absurdo, ¿dónde sería?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-romance-2', 'Si nuestra historia de amor tuviera una escena que nadie creería, ¿qué te gustaría que ocurriera?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-romance-3', '¿Qué plan romántico completamente extraño te atreverías a hacer conmigo?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.locas),
  // Conexión · Romance · alta
  _n('locas-conexion-romance-4', 'Si mañana pudiéramos desaparecer juntos durante 24 horas y hacer absolutamente cualquier cosa, ¿qué haríamos?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-romance-5', '¿Qué experiencia romántica tan absurda que normalmente nadie intentaría te gustaría vivir conmigo?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-romance-6', 'Si tuviéramos que celebrar nuestro amor de la forma más exagerada posible, ¿qué haríamos?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.locas),
  // Conexión · Nostalgia · media
  _n('locas-conexion-nostalgia-1', '¿Qué momento nuestro parece inventado cuando lo cuentas?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-nostalgia-2', '¿Cuál ha sido la situación más inesperada que terminó convirtiéndose en un buen recuerdo?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-nostalgia-3', '¿Qué recuerdo nuestro cambiarías solamente para hacerlo todavía más absurdo?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.locas),
  // Conexión · Nostalgia · alta
  _n('locas-conexion-nostalgia-4', '¿Cuál ha sido nuestra mayor locura hasta ahora?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-nostalgia-5', 'Si pudieras volver a uno de nuestros momentos más caóticos, ¿qué harías diferente?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-nostalgia-6', '¿Qué momento nuestro crees que algún día contaremos y todavía nos dará risa?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.locas),
  // Conexión · Futuro · media
  _n('locas-conexion-futuro-1', '¿Qué locura completamente inofensiva deberíamos hacer juntos algún día?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-futuro-2', 'Si pudiéramos tachar una experiencia absurda de nuestra lista este año, ¿cuál elegirías?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-futuro-3', '¿Qué tradición completamente extraña te gustaría que tuviéramos dentro de unos años?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.locas),
  // Conexión · Futuro · alta
  _n('locas-conexion-futuro-4', 'Si tuviéramos dinero, tiempo y cero responsabilidades durante una semana, ¿qué locuras haríamos?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-futuro-5', '¿Qué aventura tan improbable te gustaría vivir conmigo aunque ahora parezca una mala idea?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-futuro-6', 'Si algún día pudiéramos contar una historia diciendo "no podemos creer que realmente hicimos eso", ¿qué te gustaría que fuera?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.locas),
  // Conexión · Coqueteo · media
  _n('locas-conexion-coqueteo-1', 'Si tuvieras que conquistarme con el gesto más absurdo del mundo, ¿cuál sería?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-coqueteo-2', '¿Qué sería más peligroso: dejarnos solos en una cita elegante o en una aventura completamente improvisada?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-coqueteo-3', 'Si tuvieras que hacerme sonrojar usando solamente una situación ridícula, ¿qué inventarías?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.locas),
  // Conexión · Coqueteo · alta
  _n('locas-conexion-coqueteo-4', 'Si tuvieras permiso para provocarme durante cinco minutos sin ninguna consecuencia, ¿qué harías?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-coqueteo-5', 'Si nuestra química tuviera que expresarse mediante una situación completamente absurda, ¿qué estaría pasando?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-coqueteo-6', '¿Cuál sería la situación más inesperada en la que crees que podríamos terminar coqueteando?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.locas),
  // Conexión · Celebración · media
  _n('locas-conexion-celebracion-1', 'Si nuestra relación tuviera un premio completamente absurdo, ¿qué categoría ganaríamos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-celebracion-2', '¿Qué logro nuestro merece una celebración exageradamente innecesaria?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-celebracion-3', 'Si hoy tuviéramos que celebrar algo pequeño como si hubiéramos ganado un campeonato mundial, ¿qué celebraríamos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.locas),
  // Conexión · Celebración · alta
  _n('locas-conexion-celebracion-4', 'Si pudiéramos organizar una fiesta completamente absurda para celebrar nuestra relación, ¿qué tendría?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-celebracion-5', '¿Qué victoria nuestra celebraríamos de una forma tan absurda que nadie lo creería?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-celebracion-6', 'Si inventáramos una ceremonia anual para celebrar que seguimos juntos, ¿qué tradición ridícula tendría?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.locas),
  // Conexión · Diversión · media
  _n('locas-conexion-diversion-1', 'Si nos obligaran a competir en una disciplina completamente inventada, ¿cuál elegirías?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-diversion-2', '¿Qué reto absurdo crees que aceptaríamos solamente porque sería divertido hacerlo juntos?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-diversion-3', 'Si tuvieras que diseñar una noche completamente caótica para nosotros, ¿qué tendría que pasar?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.locas),
  // Conexión · Diversión · alta
  _n('locas-conexion-diversion-4', 'Si nadie nos viera y nada importara, ¿qué locura inofensiva haríamos juntos esta noche?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-diversion-5', '¿Cuál sería el día más absurdo que podríamos vivir juntos sin que terminara siendo una mala idea?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-diversion-6', 'Si tuvieras que convertir nuestra próxima cita en una aventura completamente impredecible, ¿qué plan harías?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.locas),
  // Conexión · Conexión · media
  _n('locas-conexion-conexion-1', '¿Qué cosa completamente absurda crees que demuestra mejor cómo somos juntos?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-conexion-2', '¿Qué locura crees que solamente te atreverías a hacer conmigo?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.locas),
  _n('locas-conexion-conexion-3', '¿Qué situación extraña crees que nos uniría todavía más si la viviéramos juntos?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.locas),
  // Conexión · Conexión · alta
  _n('locas-conexion-conexion-4', '¿Qué experiencia fuera de lo normal crees que podría convertirse en uno de nuestros recuerdos más importantes?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-conexion-5', 'Si tuviéramos que hacer algo que ninguno de los dos hubiera imaginado hacer con una pareja, ¿qué elegirías?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.locas),
  _n('locas-conexion-conexion-6', '¿Qué locura crees que algún día podríamos recordar y pensar: "solo nosotros haríamos algo así"?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.locas),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Romance · alta
  _n('locas-cierre-romance-1', 'Si pudieras terminar esta partida llevándome a una cita completamente inesperada, ¿a dónde me llevarías?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-romance-2', '¿Qué momento romántico y un poco loco te gustaría vivir conmigo algún día?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-romance-3', 'Si nuestra relación necesitara una última escena digna de una película, ¿qué estaría pasando?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.locas),
  // Cierre · Nostalgia · alta
  _n('locas-cierre-nostalgia-1', '¿Cuál ha sido la locura más bonita que hemos vivido juntos?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-nostalgia-2', '¿Qué locura nuestra recordaríamos con cariño aunque volviera a salir mal?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-nostalgia-3', '¿Qué recuerdo nuestro demuestra mejor que juntos nunca sabemos exactamente qué va a pasar?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.locas),
  // Cierre · Celebración · alta
  _n('locas-cierre-celebracion-1', 'Si tuviéramos que celebrar todo lo que hemos vivido de la manera más exagerada posible, ¿qué haríamos?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-celebracion-2', '¿Qué momento de nuestra relación merece que hoy hagamos algo completamente ridículo para celebrarlo?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-celebracion-3', 'Si nuestra relación recibiera un trofeo por todo lo que hemos vivido juntos, ¿qué diría?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.locas),
  // Cierre · Futuro · alta
  _n('locas-cierre-futuro-1', '¿Qué locura te gustaría que se convirtiera en una historia que algún día podamos contar juntos?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-futuro-2', '¿Qué aventura tenemos pendiente que no deberíamos dejar solamente en "algún día"?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-futuro-3', 'Si dentro de diez años recordáramos esta partida, ¿qué cosa te gustaría que hubiéramos terminado haciendo juntos?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.locas),
  // Cierre · Recuerdo · alta
  _n('locas-cierre-recuerdo-1', '¿Qué momento de esta partida fue suficientemente raro como para que valiera la pena recordarlo?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.locas),
  _n('locas-cierre-recuerdo-2', 'Si pudieras guardar una sola frase de esta partida para volver a reírte dentro de unos años, ¿cuál te gustaría que fuera?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.locas),

  // ════════════════════════════════════════════════════════════════════════
  // RETOS (acción: `type: QuestionType.reto`)
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Diversión · suave
  _n('retos-bienvenida-diversion-1', 'Por turnos, di una palabra y construyan juntos una historia absurda con ellas.', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-bienvenida-diversion-2', 'Cada uno tiene 10 segundos para hacer la imitación más ridícula del otro sin decir su nombre.', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-bienvenida-diversion-3', 'Inventen un nombre completamente absurdo para una película sobre su relación.', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  // Bienvenida · Descubrimiento · suave
  _n('retos-bienvenida-descubrimiento-1', 'Cada uno debe adivinar cuál es el pequeño gusto del otro que probablemente nadie más conoce.', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-bienvenida-descubrimiento-2', 'Por turnos, mencionen tres cosas que creen que el otro elegiría para sobrevivir una semana en una isla.', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-bienvenida-descubrimiento-3', 'Cada uno invente una pregunta sobre sí mismo que crea que el otro no podrá responder correctamente.', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('retos-calentamiento-descubrimiento-1', 'Cada uno tiene 20 segundos para contar algo que le gustaría aprender algún día.', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-descubrimiento-2', 'Elijan una habilidad que creen que el otro podría aprender rápidamente y expliquen por qué.', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-descubrimiento-3', 'Cada uno debe decir una cosa que siempre ha querido probar, aunque todavía no lo haya hecho.', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Descubrimiento · media
  _n('retos-calentamiento-descubrimiento-4', 'Cada uno cuente una experiencia que le haya cambiado ligeramente la forma de pensar.', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-descubrimiento-5', 'Por turnos, intenten adivinar qué decisión del otro creen que ha influido más en quién es actualmente.', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-descubrimiento-6', 'Cada uno diga algo que le gustaría que el otro conociera mejor sobre su forma de ser.', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Diversión · suave
  _n('retos-calentamiento-diversion-1', 'Durante 30 segundos, solo pueden comunicarse usando gestos. El otro debe intentar adivinar qué quieren decir.', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-diversion-2', 'Inventen juntos el peor nombre posible para una mascota y defiendan por qué sería perfecto.', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-diversion-3', 'Cada uno debe crear un apodo nuevo para el otro en menos de 10 segundos.', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Diversión · media
  _n('retos-calentamiento-diversion-4', 'Cada uno tiene que representar cómo actúa el otro cuando tiene mucha hambre. El primero que se ría pierde.', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-diversion-5', 'Cada uno invente una ley absurda que debería existir y defiendan por qué.', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-diversion-6', 'Imaginen que tienen que abrir un negocio juntos. En 30 segundos inventen el negocio, su nombre y qué venderían.', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Nostalgia · suave
  _n('retos-calentamiento-nostalgia-1', 'Cada uno cuente un recuerdo de su infancia que le gustaría poder repetir durante un día.', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-nostalgia-2', 'Elijan una canción que les recuerde una etapa importante de su vida y expliquen por qué.', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-nostalgia-3', 'Cada uno describa un lugar de su infancia que le gustaría enseñarle al otro.', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Nostalgia · media
  _n('retos-calentamiento-nostalgia-4', 'Cada uno cuente una pequeña tradición de su infancia que le gustaría conservar.', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-nostalgia-5', 'Imaginen que pueden volver a vivir un día de su pasado durante 24 horas. Cada uno elija cuál y explique por qué.', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-nostalgia-6', 'Cada uno cuente una experiencia que en su momento parecía pequeña, pero que ahora recuerda con mucho cariño.', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Conexión · suave
  _n('retos-calentamiento-conexion-1', 'Cada uno diga una cosa pequeña que el otro hace y que le alegra el día.', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-conexion-2', 'Por turnos, completen: "Me gusta cuando nosotros...".', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-conexion-3', 'Cada uno diga un momento reciente en el que se sintió especialmente cómodo estando con el otro.', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.retos, type: QuestionType.reto),
  // Calentamiento · Conexión · media
  _n('retos-calentamiento-conexion-4', 'Cada uno debe decir algo que le gustaría hacer más seguido juntos.', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-conexion-5', 'Por turnos, describan una cosa que creen que hace especial su relación.', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-calentamiento-conexion-6', 'Cada uno diga una pequeña costumbre que le gustaría convertir en una tradición entre ustedes.', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Romance · media
  _n('retos-conexion-romance-1', 'Mírense durante unos segundos sin hablar. Después, cada uno diga qué fue lo primero que pensó.', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-romance-2', 'Cada uno debe elegir una cualidad del otro que le parezca especialmente atractiva y explicar por qué.', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-romance-3', 'Por turnos, completen: "Una de las cosas que más me gusta de estar contigo es...".', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Romance · alta
  _n('retos-conexion-romance-4', 'Cada uno debe decirle al otro algo romántico que normalmente le daría un poco de vergüenza decir en voz alta.', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-romance-5', 'Imaginen su cita perfecta. Cada uno debe describir una parte de ella y después intenten unir ambas ideas.', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-romance-6', 'Mírense durante 20 segundos y después díganse qué sienten cuando están así juntos.', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Nostalgia · media
  _n('retos-conexion-nostalgia-1', 'Cada uno elija un recuerdo juntos y cuente qué parte de ese momento recuerda con más cariño.', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-nostalgia-2', 'Intenten reconstruir entre los dos uno de sus primeros momentos juntos, incluyendo detalles que recuerden.', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-nostalgia-3', 'Cada uno recree un momento de ustedes dos con lujo de detalle, como si estuviera pasando otra vez.', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Nostalgia · alta
  _n('retos-conexion-nostalgia-4', 'Cada uno cuente un momento de su relación que haya cambiado la forma en que veía al otro.', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-nostalgia-5', 'Elijan un recuerdo que ambos tengan y cuenten qué significa para cada uno actualmente.', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-nostalgia-6', 'Cada uno diga qué momento de su historia juntos espera recordar dentro de muchos años.', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Futuro · media
  _n('retos-conexion-futuro-1', 'Diseñen en un minuto una pequeña aventura que puedan hacer juntos durante el próximo mes.', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-futuro-2', 'Cada uno proponga algo nuevo que le gustaría experimentar juntos durante este año.', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-futuro-3', 'Imaginen que mañana tienen todo el día libre y ningún límite de dinero. Decidan juntos qué harían.', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Futuro · alta
  _n('retos-conexion-futuro-4', 'Cada uno imagine un día normal de su vida juntos dentro de cinco años y describa qué estaría pasando.', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-futuro-5', 'Inventen una tradición que les gustaría tener cuando lleven muchos años juntos.', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-futuro-6', 'Cada uno diga una experiencia que le gustaría poder recordar algún día diciendo: "Esto lo vivimos juntos".', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Coqueteo · media
  _n('retos-conexion-coqueteo-1', 'Cada uno debe inventar una frase de coqueteo que describa al otro sin utilizar la palabra "bonito", "guapo" o "sexy".', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-coqueteo-2', 'Durante un minuto, intenten impresionarse mutuamente sin tocarse.', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-coqueteo-3', 'Cada uno debe elegir qué gesto del otro considera más irresistible y demostrarlo sin explicarlo con palabras.', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Coqueteo · alta
  _n('retos-conexion-coqueteo-4', 'Mírense durante 20 segundos. El primero que aparte la mirada debe decir algo que le atraiga del otro.', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-coqueteo-5', 'Cada uno debe susurrarle al otro un cumplido que normalmente no diría delante de otras personas.', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-coqueteo-6', 'Acérquense todo lo que ambos consideren cómodo y mantengan la mirada durante unos segundos. Después, cada uno diga qué sintió.', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Celebración · media
  _n('retos-conexion-celebracion-1', 'Cada uno debe celebrar un logro del otro como si acabara de ganar un premio importante.', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-celebracion-2', 'Inventen un premio absurdo que el otro merezca y hagan una pequeña ceremonia para entregárselo.', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-celebracion-3', 'Cada uno diga una cosa del otro que cree que merece ser reconocida más de lo que normalmente se reconoce.', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Celebración · alta
  _n('retos-conexion-celebracion-4', 'Cada uno debe decirle al otro cuál considera que ha sido uno de sus mayores logros y por qué se siente orgulloso de él.', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-celebracion-5', 'Imaginen que están celebrando juntos un gran logro dentro de diez años. Inventen el discurso que darían esa noche.', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-celebracion-6', 'Cada uno debe dedicarle al otro un pequeño discurso de 30 segundos sobre algo que admira profundamente de él.', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Diversión · media
  _n('retos-conexion-diversion-1', 'Inventen juntos una teoría completamente absurda sobre cómo se conocieron realmente.', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-diversion-2', 'Cada uno debe imitar al otro intentando convencerlo de algo completamente ridículo.', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-diversion-3', 'Durante un minuto, actúen como si fueran una pareja famosa siendo entrevistada sobre su relación.', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Diversión · alta
  _n('retos-conexion-diversion-4', 'Inventen una discusión absurda sobre algo completamente inútil y defiendan su postura como si fuera importantísima.', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-diversion-5', 'Cada uno debe representar cómo sería el otro si fuera un villano de película. El otro decide quién hizo la mejor actuación.', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-diversion-6', 'Imaginen que mañana despiertan intercambiando personalidades. Cada uno debe explicar cómo pasaría el primer día siendo el otro.', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Conexión · media
  _n('retos-conexion-conexion-1', 'Cada uno debe decir algo que le gustaría que nunca cambiara entre ustedes.', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-conexion-2', 'Tómense un momento para recordar cómo se sentían al principio de su relación y cada uno diga qué ha cambiado para mejor.', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-conexion-3', 'Cada uno debe elegir una pequeña cosa que puedan hacer esta semana para sentirse más conectados.', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.retos, type: QuestionType.reto),
  // Conexión · Conexión · alta
  _n('retos-conexion-conexion-4', 'Cada uno debe completar sinceramente: "Contigo siento que puedo...".', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  _n('retos-conexion-conexion-5', 'Mírense durante unos segundos y después cada uno diga algo que siente que ha aprendido gracias al otro.', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Romance · alta
  _n('retos-cierre-romance-1', 'Cada uno debe decirle al otro una cosa que quiere seguir haciendo para cuidar su relación.', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Cierre · Nostalgia · alta
  _n('retos-cierre-nostalgia-1', 'Cada uno elija un momento que haya vivido con el otro y que le gustaría recordar exactamente así dentro de muchos años.', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Cierre · Celebración · alta
  _n('retos-cierre-celebracion-1', 'Cada uno debe decir cuál es la cosa de su relación que más orgullo le da haber construido juntos.', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Cierre · Futuro · alta
  _n('retos-cierre-futuro-1', 'Abracen o tómense de la mano durante un momento y cada uno diga algo que le gustaría vivir junto al otro próximamente.', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),
  // Cierre · Recuerdo · alta
  _n('retos-cierre-recuerdo-1', 'Guarden juntos una frase que describa cómo se sienten después de todo lo que han compartido en esta partida.', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.retos, type: QuestionType.reto),

  // ════════════════════════════════════════════════════════════════════════
  // INCÓMODAS
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Descubrimiento · suave
  _n('incomodas-bienvenida-descubrimiento-1', '¿Qué cosa de ti te cuesta un poco admitir cuando alguien te pregunta?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-bienvenida-descubrimiento-2', '¿Qué hábito tuyo sabes que es raro, pero prefieres no contar de inmediato?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-bienvenida-descubrimiento-3', '¿Qué opinión tuya suele sorprender a las personas que te conocen?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-bienvenida-descubrimiento-4', '¿Qué cosa haces cuando estás nervioso que probablemente no notas?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  // Bienvenida · Diversión · suave
  _n('incomodas-bienvenida-diversion-1', '¿Cuál ha sido la situación más ridícula en la que has intentado quedar bien?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-bienvenida-diversion-2', '¿Qué mentira pequeña has dicho alguna vez para evitar una situación incómoda?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-bienvenida-diversion-3', '¿Qué cosa haces cuando nadie te está viendo que jamás admitirías fácilmente?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.incomodas),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('incomodas-calentamiento-descubrimiento-1', '¿Qué pequeño defecto tuyo crees que la gente nota antes de conocerte bien?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-2', '¿Qué parte de tu personalidad tardaste tiempo en aceptar?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-3', '¿Qué cosa te da un poco de vergüenza que te guste?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.incomodas),
  // Calentamiento · Diversión · suave
  _n('incomodas-calentamiento-diversion-1', '¿Cuál es tu peor excusa para no hacer algo?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-2', '¿Qué error tonto sigues recordando aunque haya pasado mucho tiempo?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-3', '¿Qué intentaste impresionarme con eso que terminó en anécdota?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.incomodas),
  // Calentamiento · Nostalgia · suave
  _n('incomodas-calentamiento-nostalgia-1', '¿Qué recuerdo de tu infancia te da un poco de vergüenza recordar?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-2', '¿Qué cosa hacías de pequeño que ahora jamás harías delante de alguien?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-3', '¿Qué etapa de tu vida te gustaría poder volver a visitar por un día?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-4', '¿Qué error de tu adolescencia todavía recuerdas perfectamente?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-5', '¿Qué persona de tu pasado te enseñó algo que todavía llevas contigo?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-6', '¿Qué recuerdo te hace pensar "¿en qué estaba pensando?"?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-7', '¿Qué cosa de cómo eras antes te alegra haber dejado atrás?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.incomodas),
  // Calentamiento · Conexión · suave
  _n('incomodas-calentamiento-conexion-1', '¿Qué cosa pequeña hago que a veces te pone nervioso?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-2', '¿Qué espacio tuyo te costó más trabajo abrirme y por qué hoy es importante?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-3', '¿Hay algo que haces conmigo porque sabes que me gusta, aunque a ti no te encante?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-4', '¿Qué cosa de mí te sorprendió cuando empezamos a conocernos?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-5', '¿Qué hábito mío te cuesta entender?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-6', '¿Qué cosa crees que todavía no conozco completamente de ti?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-7', '¿Qué pequeño detalle mío te gustaría que notara más?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.incomodas),
  // Calentamiento · Descubrimiento · media
  _n('incomodas-calentamiento-descubrimiento-4', '¿Qué inseguridad tuya intentas esconder cuando conoces a alguien?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-5', '¿Qué crítica te cuesta más aceptar aunque sepas que puede ser cierta?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-6', '¿Qué aspecto de tu personalidad has intentado cambiar y no has conseguido?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-7', '¿Qué cosa necesitas de los demás pero te cuesta pedir?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-8', '¿Qué parte de ti crees que las personas suelen malinterpretar?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-9', '¿Qué miedo pequeño influye más en tus decisiones de lo que te gustaría admitir?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-10', '¿Qué error has cometido varias veces aunque sabes que deberías haber aprendido?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  // Calentamiento · Diversión · media
  _n('incomodas-calentamiento-diversion-4', '¿Cuál es la peor decisión que has tomado por querer quedar bien?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-5', '¿Qué momento te gustaría poder borrar de internet?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-6', '¿Cuál ha sido tu peor intento de fingir que sabías algo que en realidad no sabías?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-7', '¿Qué cosa has hecho por orgullo y después te arrepentiste?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-8', '¿Cuál es la excusa más absurda que has usado para no admitir que te equivocaste?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-9', '¿Qué situación te hizo pensar "trágame tierra"?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-diversion-10', '¿Qué cosa haces cuando estás celoso aunque intentes disimularlo?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.incomodas),
  // Calentamiento · Nostalgia · media
  _n('incomodas-calentamiento-nostalgia-8', '¿Qué canción te transporta a un momento exacto de tu pasado sin que puedas evitarlo?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-9', '¿Qué decisión de tu pasado cambiarías si pudieras?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-10', '¿Qué error del pasado todavía influye en cómo actúas hoy?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-11', '¿Hay algo que nunca dijiste cuando tuviste la oportunidad?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-12', '¿Qué relación de tu pasado te enseñó más sobre lo que no quieres repetir?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-13', '¿Qué lugar de tu pasado te gustaría volver a visitar para ver cómo se ve hoy?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-nostalgia-14', '¿Qué parte de tu yo de antes te hace sonreír al recordarla, aunque ya no seas esa persona?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.incomodas),
  // Calentamiento · Conexión · media
  _n('incomodas-calentamiento-conexion-8', '¿Qué experiencia nuestra te gustaría proteger para que nada la cambie?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-9', '¿Qué cosa te gustaría pedirme más seguido sin sentir que molestas?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-10', '¿Qué hago sin querer que puede hacerte sentir mal?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-11', '¿De qué tema nuestro hablamos poco y te gustaría hablar más?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-12', '¿En qué momento reciente sentiste que tenías que aparentar estar bien y no lo estabas del todo?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-13', '¿Qué cosa te gustaría que entendiera mejor de ti?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-conexion-14', '¿Qué frase te has guardado alguna vez y hoy sí podrías decirme?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.incomodas),
  // Calentamiento · Descubrimiento · media (reclasificadas desde
  // "Descubrimiento · alta": descubrimiento no vive en Conexión/Cierre).
  _n('incomodas-calentamiento-descubrimiento-11', '¿Qué opinión tuya cambió por completo en los últimos años?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-12', '¿Qué cosa cotidiana te da más miedo de lo que admitirías, como volar o hablar en público?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-13', '¿Cuál es la mejor lección que te enseñó un error?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-14', '¿Qué etapa de tu vida te gustaría volver a vivir por primera vez?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-15', '¿Qué cosa de ti que casi nadie sabe te hace más interesante?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-16', '¿Qué cosa de ti has aprendido a aceptar con los años?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),
  _n('incomodas-calentamiento-descubrimiento-17', '¿Qué aspecto de ti mismo te gustaría poder cambiar inmediatamente?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.incomodas),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Diversión · alta
  _n('incomodas-conexion-diversion-1', '¿Cuál ha sido la vez que más has fingido tener todo bajo control cuando no era así?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-diversion-2', '¿Qué decisión absurda tomaste porque tu orgullo no te dejó reconocer que estabas equivocado?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-diversion-3', '¿Qué situación te hizo darte cuenta de que eres mucho más sensible de lo que aparentas?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-diversion-4', '¿Cuál es la cosa más inmadura que todavía haces cuando estás molesto?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-diversion-5', '¿Qué discusión has perdido pero nunca has querido admitir?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-diversion-6', '¿Qué cosa te cuesta muchísimo reconocer cuando alguien tiene razón?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-diversion-7', '¿Cuál es una verdad incómoda sobre ti que ahora puedes admitir con una sonrisa?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.incomodas),
  // Conexión · Nostalgia · alta
  _n('incomodas-conexion-nostalgia-1', '¿Qué cosa de tu pasado todavía estás intentando perdonarte?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-nostalgia-2', '¿Qué momento difícil te convirtió en la persona que eres hoy?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),
  // Conexión · Conexión · alta
  _n('incomodas-conexion-conexion-1', '¿Cuál es tu mayor miedo dentro de una relación?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-2', '¿Qué podría hacer yo que realmente rompiera tu confianza?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-3', '¿Hay algo que te haya dolido de nuestra relación y que nunca hayas sabido cómo decirme?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-4', '¿Qué parte de ti tienes más miedo de mostrarme completamente?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-5', '¿Cuándo has sentido más miedo de perderme?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-6', '¿Qué necesitas escuchar de mí cuando estás pasando por un momento difícil?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-7', '¿Hay algo que quieras cambiar de nuestra relación pero te daba miedo proponerlo?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-8', '¿Qué crees que todavía no entiendo completamente sobre cómo amas?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-9', '¿Cuál es una inseguridad que nuestra relación ha despertado en ti?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-10', '¿Hay algo que hayas perdonado pero que todavía te cuesta olvidar?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-11', '¿Qué límite tuyo crees que debería conocer mejor?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-12', '¿Qué cosa jamás quisieras que dejáramos de hacer como pareja?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-13', '¿Qué sería para ti una señal de que nuestra relación está dejando de ser saludable?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-14', '¿Qué preocupación sobre nosotros nunca te he visto nombrar?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-15', '¿Cuándo te has sentido más expuesto/a conmigo y cómo te acompañé?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-16', '¿Qué cosa necesitas de mí cuando estamos en medio de un conflicto?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-17', '¿Qué verdad sobre nuestra relación crees que ambos deberíamos atrevernos a hablar?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-18', '¿Qué crees que podríamos mejorar aunque todo entre nosotros esté bien?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-19', '¿Qué error tuyo dentro de nuestra relación te gustaría reparar?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-20', '¿Qué cosa te cuesta más decirme cuando estás enojado?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-21', '¿Qué promesa te gustaría que nunca rompiéramos?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-22', '¿Qué recuerdo nuestro te da más miedo que se pierda con el tiempo?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-conexion-conexion-23', 'Si pudieras preguntarme algo sin miedo a mi reacción, ¿qué me preguntarías?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.incomodas),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Nostalgia · alta
  _n('incomodas-cierre-nostalgia-1', '¿Hay algo por lo que te gustaría pedirme perdón hoy y cerrar esa página juntos?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-cierre-nostalgia-2', '¿Qué recuerdo todavía te duele aunque haya pasado mucho tiempo?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-cierre-nostalgia-3', '¿Qué persona te hizo daño y qué aprendiste de aquello?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-cierre-nostalgia-4', '¿Qué despedida de tu vida sentiste que quedó incompleta?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),
  _n('incomodas-cierre-nostalgia-5', '¿Qué decisión del pasado cambió tu forma de confiar en los demás?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.incomodas),

  // ════════════════════════════════════════════════════════════════════════
  // EXTREMAS
  // ════════════════════════════════════════════════════════════════════════

  // ── Bienvenida ─────────────────────────────────────────────────────────
  // Bienvenida · Descubrimiento · suave
  _n('extremas-bienvenida-descubrimiento-1', '¿Qué cosa de ti que no se nota a simple vista te hace ser quien eres?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-bienvenida-descubrimiento-2', '¿Qué manía o costumbre tuya crees que sería la primera que se notaría en una convivencia?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-bienvenida-descubrimiento-3', '¿Qué cosa de ti todavía estás intentando mejorar?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-bienvenida-descubrimiento-4', '¿Qué cosa de tu vida cotidiana te parece fascinante y casi nadie te pregunta por ella?', Chapter.bienvenida, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  // Bienvenida · Diversión · suave
  _n('extremas-bienvenida-diversion-1', '¿Cuál ha sido la decisión más impulsiva que has tomado?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-bienvenida-diversion-2', '¿Qué es lo más absurdo que harías por alguien que quieres?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-bienvenida-diversion-3', '¿Qué locura has hecho y probablemente volverías a hacer?', Chapter.bienvenida, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),

  // ── Calentamiento ──────────────────────────────────────────────────────
  // Calentamiento · Descubrimiento · suave
  _n('extremas-calentamiento-descubrimiento-1', '¿Qué decisión importante has tomado sin estar realmente seguro de haber hecho lo correcto?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-2', '¿Qué parte de tu forma de pensar suele ser difícil de explicar a los demás?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-3', '¿Qué cosa sobre ti tardaste mucho tiempo en aceptar?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.suave, QuestionCategory.extremas),
  // Calentamiento · Diversión · suave
  _n('extremas-calentamiento-diversion-1', '¿Cuál ha sido tu mayor "¿qué estaba pensando?"?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-2', '¿Qué regla romperías si supieras que nadie se enteraría?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-3', '¿Qué harías si mañana tuvieras que empezar completamente de cero?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-4', '¿Cuál es la cosa más arriesgada que te gustaría hacer algún día?', Chapter.calentamiento, Emotion.diversion, Intensity.suave, QuestionCategory.extremas),
  // Calentamiento · Nostalgia · suave
  _n('extremas-calentamiento-nostalgia-1', '¿Qué momento de tu vida cambió tu forma de ver las relaciones?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-2', '¿Qué experiencia del pasado te hizo madurar de golpe?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-3', '¿Qué persona de tu pasado influyó más en quién eres actualmente?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-4', '¿Qué etapa de tu vida nunca repetirías?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-5', '¿Qué decisión del pasado todavía te genera dudas?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-6', '¿Qué recuerdo te gustaría poder experimentar una última vez?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-7', '¿Qué aprendiste demasiado tarde?', Chapter.calentamiento, Emotion.nostalgia, Intensity.suave, QuestionCategory.extremas),
  // Calentamiento · Conexión · suave
  _n('extremas-calentamiento-conexion-1', '¿Qué fue lo que más te sorprendió de nuestra relación al principio?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-2', '¿Qué cosa de nosotros nunca imaginaste que terminaría siendo importante?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-3', '¿Qué parte de nuestra relación crees que nos hace diferentes de otras parejas?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-4', '¿Qué cosa de mí crees que todavía no comprendes completamente?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-5', '¿Qué gesto nuestro quieres que siga siendo igual de especial dentro de diez años?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-6', '¿Qué cosa hacemos juntos que esperas recordar dentro de muchos años?', Chapter.calentamiento, Emotion.conexion, Intensity.suave, QuestionCategory.extremas),
  // Calentamiento · Conexión · media
  _n('extremas-calentamiento-conexion-7', '¿Qué detalle de mi forma de ser has ido adoptando poco a poco?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-8', '¿Qué parte de nuestra historia contarías primero si algún día alguien nos preguntara cómo empezó todo?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-9', '¿Qué crees que es lo más fuerte que tenemos como pareja?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-10', '¿Qué crees que todavía tenemos que aprender juntos?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-11', '¿Qué momento hizo que sintieras que nuestra relación era diferente?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-12', '¿Qué cosa de nosotros te gustaría proteger a toda costa?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  // Calentamiento · Descubrimiento · media
  _n('extremas-calentamiento-descubrimiento-4', '¿Qué aspecto de tu forma de amar crees que podría ser difícil para otra persona?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-5', '¿Qué miedo podría hacerte tomar una mala decisión en una relación?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-6', '¿Qué cosa necesitas aprender antes de estar preparado para una relación realmente seria?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-7', '¿Qué parte de tu carácter puede hacerte difícil pedir perdón?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-8', '¿Qué error nunca quieres repetir en una relación?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-9', '¿Qué situación podría hacerte perder la confianza en alguien?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-10', '¿Qué valor nunca estarías dispuesto a sacrificar por una relación?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-11', '¿Qué diferencia entre dos personas crees que puede terminar siendo imposible de ignorar?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  // Calentamiento · Diversión · media
  _n('extremas-calentamiento-diversion-5', 'Si tuvieras que elegir entre vivir una aventura enorme conmigo o tener una vida completamente tranquila, ¿qué elegirías?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-6', '¿Qué locura harías conmigo que probablemente nuestros amigos considerarían una mala idea?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-7', 'Si pudiéramos desaparecer durante un mes sin preocuparnos por dinero, ¿a dónde iríamos?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-8', '¿Qué cosa completamente inesperada aceptarías hacer conmigo?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-9', 'Si mañana nos regalaran un boleto a cualquier lugar del mundo, ¿qué tan rápido harías la maleta?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-10', '¿Qué experiencia extrema te gustaría vivir al menos una vez conmigo?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-diversion-11', '¿Qué reto crees que ninguno de los dos se atrevería a aceptar?', Chapter.calentamiento, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  // Calentamiento · Nostalgia · media
  _n('extremas-calentamiento-nostalgia-8', '¿Qué gesto pequeño de una persona de tu pasado todavía agradeces hoy?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-9', '¿Qué error de tu pasado todavía influye en cómo actúas conmigo?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-10', '¿Qué aprendiste de una persona que ya no forma parte de tu vida?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-11', '¿Qué viaje de tu pasado recuerdas como si hubiera pasado ayer?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-12', '¿Qué momento difícil te hizo cambiar como persona?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-13', '¿Qué historia de tu pasado contarías primero si solo pudieras contarme una?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-14', '¿Qué decisión de tu pasado te gustaría que yo entendiera antes de juzgarla?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-nostalgia-15', '¿Qué relación de tu pasado te dejó la mejor anécdota para contar?', Chapter.calentamiento, Emotion.nostalgia, Intensity.media, QuestionCategory.extremas),
  // Calentamiento · Conexión · media
  _n('extremas-calentamiento-conexion-13', '¿Qué diferencia entre nosotros crees que podría convertirse en un problema si algún día crece?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-14', '¿Sobre qué tema te gustaría que habláramos más para no guardarnos cosas?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-15', '¿Qué parte de nuestra relación crees que necesita más atención?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-16', '¿Qué costumbre pequeña crees que nos mantiene cerca aunque no nos demos cuenta?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-17', '¿Qué actitud nuestra no quieres que se convierta en costumbre?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-conexion-18', '¿Qué tema de nuestro futuro te gustaría que habláramos hoy mismo?', Chapter.calentamiento, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  // Calentamiento · Descubrimiento · media (reclasificadas desde
  // "Descubrimiento · alta": descubrimiento no vive en Conexión/Cierre).
  _n('extremas-calentamiento-descubrimiento-12', '¿Qué te asusta de no lograr el futuro que imaginas para ti?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-13', '¿Qué cosa sobre ti que casi nadie conoce te definiría si se supiera?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-14', '¿Qué verdad sobre ti te costaría muchísimo que alguien aceptara?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-15', '¿Qué aspecto de tu personalidad cambiarías si pudieras hacerlo inmediatamente?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-16', '¿Qué decisión equivocada te hizo más sabio para las siguientes?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-17', '¿Qué cosa desearías tener el valor de hacer aunque sea una vez en la vida?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-18', '¿Qué cosa de ti te costó más tiempo aprender a querer?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-19', '¿Qué verdad sobre tu vida te ha costado más aceptar?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-20', '¿Qué parte de tu futuro te asusta más?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),
  _n('extremas-calentamiento-descubrimiento-21', '¿Qué parte de ti crees que perderías si vivieras solo para complacer a los demás?', Chapter.calentamiento, Emotion.descubrimiento, Intensity.media, QuestionCategory.extremas),

  // ── Conexión ───────────────────────────────────────────────────────────
  // Conexión · Conexión · media
  _n('extremas-conexion-conexion-1', '¿Qué crees que podríamos hacer mejor cuando discutimos?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-2', '¿Qué necesitas de mí cuando estás decepcionado conmigo?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-3', '¿Qué comportamiento mío sería difícil para ti perdonar?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-4', '¿Qué diferencia entre nosotros te parece más importante aprender a manejar?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-5', '¿Qué crees que deberíamos proteger incluso durante una etapa difícil?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-6', '¿Qué sería para ti una señal de que necesitamos cambiar algo en nuestra relación?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-7', '¿Qué sacrificio sí harías por nuestra relación?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-8', '¿Qué sacrificio nunca harías, aunque me quisieras muchísimo?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.extremas),
  // Conexión · Nostalgia · alta
  _n('extremas-conexion-nostalgia-1', '¿Qué momento de nuestra historia te gustaría revivir para decirme algo que en su momento no dijiste?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-2', '¿Qué decisión de tu pasado cambiarías aunque eso significara no convertirte en quien eres hoy?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-3', '¿Qué herida del pasado crees que todavía influye en cómo quieres?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-4', '¿Qué experiencia te enseñó a desconfiar?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-5', '¿Qué persona perdiste y todavía te preguntas cómo habría sido tu vida si siguiera contigo?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-6', '¿Qué parte de tu pasado temes que algún día vuelva a afectarte?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-7', '¿Qué perdón todavía te cuesta dar?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-nostalgia-8', '¿Qué cosa de tu pasado te gustaría que yo pudiera entender completamente?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  // Conexión · Conexión · alta
  _n('extremas-conexion-conexion-9', '¿Qué podría hacer que dejaras de confiar completamente en mí?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-10', '¿Qué límite entre nosotros crees que no deberíamos cruzar nunca, aunque estemos enojados?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-11', '¿Qué costumbre nuestra valoras tanto que te daría miedo que desapareciera?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-12', '¿Cuál crees que sería nuestro mayor riesgo como pareja a largo plazo?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-13', '¿Qué verdad sobre nuestra relación crees que podría ser difícil para ambos aceptar?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-14', '¿Qué actitud tuya o mía crees que nunca debería volverse normal entre nosotros?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-15', '¿Qué miedo tienes sobre nuestro futuro que todavía no me has contado?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-16', '¿Qué crees que podría alejarnos si dejamos de cuidarlo?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-17', '¿Qué parte de ti todavía tienes miedo de entregarme completamente?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-18', '¿Qué es lo que nunca te gustaría perder de cómo somos juntos, incluso si la vida nos cambia?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-conexion-19', '¿Qué conversación crees que deberíamos tener para que lo difícil de nosotros se sienta más fácil?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.extremas),
  // Conexión · Romance · media
  _n('extremas-conexion-romance-1', '¿Qué parte de mí te hace querer quedarte incluso en los días difíciles?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-romance-2', '¿Qué crees que es lo más vulnerable que me has visto hacer por ti?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-romance-3', '¿Qué necesidad tuya crees que yo todavía no logro entender del todo?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.extremas),
  // Conexión · Romance · alta
  _n('extremas-conexion-romance-4', '¿Qué harías por mí que nunca has hecho por nadie más?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-romance-5', '¿Qué parte de tu corazón todavía no te atreves a mostrarme?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-romance-6', '¿Qué me pedirías si supieras que no puedo decirte que no?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.extremas),
  // Conexión · Futuro · media
  _n('extremas-conexion-futuro-1', '¿Qué temes del futuro y hasta ahora solo lo has pensado en silencio?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-futuro-2', '¿Qué parte de la vida que imaginas conmigo sabes que será difícil?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-futuro-3', '¿Qué harías diferente en nuestra relación dentro de diez años?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.extremas),
  // Conexión · Futuro · alta
  _n('extremas-conexion-futuro-4', '¿Qué sacrificio estarías dispuesto a hacer para que nuestro futuro juntos funcione?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-futuro-5', '¿Qué te aterra que pueda pasar con nosotros dentro de unos años?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-futuro-6', 'Si supieras que vamos a estar juntos toda la vida, ¿qué cambiarías hoy de nuestra relación?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.extremas),
  // Conexión · Coqueteo · media
  _n('extremas-conexion-coqueteo-1', '¿Qué detalle de mí te pone en el estado de ánimo más coqueto?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-coqueteo-2', '¿Qué fantasía ligera sobre nosotros nunca te has atrevido a mencionar?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-coqueteo-3', '¿Qué parte de mí te sigue atrayendo más que cuando empezamos?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.extremas),
  // Conexión · Coqueteo · alta
  _n('extremas-conexion-coqueteo-4', '¿Qué harías conmigo esta noche si supiéramos que nadie se enterará jamás?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-coqueteo-5', '¿Qué deseo sobre nosotros me dirías solo si estuvieras seguro de que no lo juzgaré?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-coqueteo-6', '¿Qué es lo más atrevido que te gustaría que te pidiera?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.extremas),
  // Conexión · Celebración · media
  _n('extremas-conexion-celebracion-1', '¿Qué logro nuestro crees que no celebramos lo suficiente?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-celebracion-2', '¿Qué momento de nosotros te hace sentir que somos un gran equipo?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-celebracion-3', '¿Qué cosa pequeña deberíamos empezar a celebrar cada mes?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.extremas),
  // Conexión · Celebración · alta
  _n('extremas-conexion-celebracion-4', '¿Qué celebración te atreverías a organizar conmigo que nunca hemos hecho?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-celebracion-5', '¿Qué queremos celebrar juntos dentro de un año que hoy nos parezca imposible?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-celebracion-6', '¿Qué victoria de nuestra relación te enorgullece más contarle a los demás?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.extremas),
  // Conexión · Diversión · media
  _n('extremas-conexion-diversion-1', '¿Qué reto nos pondríamos que probablemente termine mal pero sea inolvidable?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-diversion-2', '¿Qué juego de pareja crees que nos sacaría el lado más tonto?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  _n('extremas-conexion-diversion-3', '¿Qué plan absurdo conmigo has imaginado aunque nunca lo hayas propuesto?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.extremas),
  // Conexión · Diversión · alta
  _n('extremas-conexion-diversion-4', '¿Qué locura harías conmigo esta noche sin pensarlo dos veces?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-diversion-5', '¿Qué desafío extremo aceptarías conmigo si supiéramos que estamos a salvo?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.extremas),
  _n('extremas-conexion-diversion-6', '¿Qué cosa prohibida disfrutaríamos hacer juntos si no tuviera consecuencias?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.extremas),

  // ── Cierre ─────────────────────────────────────────────────────────────
  // Cierre · Romance · alta
  _n('extremas-cierre-romance-1', '¿Qué parte de esta partida te hace sentir que podemos atravesar lo difícil estando juntos?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.extremas),
  // Cierre · Nostalgia · alta
  _n('extremas-cierre-nostalgia-1', '¿Qué momento difícil que ya pasamos juntos te hace sentir orgulloso/a de lo que somos?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.extremas),
  // Cierre · Celebración · alta
  _n('extremas-cierre-celebracion-1', '¿Qué deberíamos celebrar hoy después de habernos atrevido a hablar de todo esto?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.extremas),
  // Cierre · Futuro · alta
  _n('extremas-cierre-futuro-1', '¿Qué promesa sobre nuestro futuro quieres hacerme ahora que ya conoces lo más difícil de mí?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.extremas),
  // Cierre · Recuerdo · alta
  _n('extremas-cierre-recuerdo-1', '¿Qué quieres que recordemos siempre de esta partida, aun cuando lleguen tiempos difíciles?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.extremas),
];

/// Constructor del lote temático: id `nue-<prefijo>`, `QuestionSource.original`
/// y por defecto `status: listo`.
GameQuestion _n(
  String prefix,
  String text,
  Chapter chapter,
  Emotion emotion,
  Intensity intensity,
  QuestionCategory category, {
  QuestionType type = QuestionType.conversacion,
  List<String> options = const [],
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
      options: options,
      isSpecial: isSpecial,
      source: QuestionSource.original,
      status: status,
    );
