import '../domain/enums/chapter.dart';
import '../domain/enums/emotion.dart';
import '../domain/enums/intensity.dart';
import '../domain/enums/migration.dart';
import '../domain/enums/question_category.dart';
import '../domain/enums/question_type.dart';
import '../domain/models/game_question.dart';

/// Lote de comparaciones del banco V1 (ids `nue-comparacion-*`).
///
/// Las comparaciones son el formato donde ambos responden la misma pregunta y
/// luego se comparan las respuestas ("¿quién de los dos...?"). Viven en los
/// capítulos que las permiten (`GameChapter.forChapter`): **Conexión**
/// (romance, nostalgia, futuro, coqueteo, celebración, diversión, conexión;
/// intensidad media/alta) y **Cierre** (romance, nostalgia, celebración,
/// futuro, recuerdo; intensidad alta).
///
/// Este lote tiene dos misiones:
///
///  - **Cobertura de la cuota del motor**: `GameEngine` garantiza al menos
///    1/2/3 comparaciones por partida (según 10/20/25 rondas). Para que esos
///    espacios forzados tengan preguntas, el banco cubre cada emoción ×
///    intensidad × capítulo jugable con varias alternativas por categoría.
///  - **Variedad real**: cuantas más comparaciones haya por celda, más
///    orgánicamente aparece el formato en la mezcla de la partida.
///
/// Reglas del lote (validadas por los tests del motor):
///  - id `nue-comparacion-<categoria>-<capitulo>-<emocion>-<n>`;
///  - `type: QuestionType.comparacion` y exactamente **2 opciones** no vacías
///    (una por jugador), con la forma "Yo... / Tú...";
///  - capítulo/emoción/intensidad dentro del pool y la rampa del capítulo;
///  - `QuestionSource.original` y `status: listo`.
final List<GameQuestion> comparisonQuestionsV1 = <GameQuestion>[
  // ════════════════════════════════════════════════════════════════════════
  // ROMÁNTICAS · Conexión
  // ════════════════════════════════════════════════════════════════════════
  // Conexión · Romance · media
  _c('romanticas-conexion-romance-1', '¿Quién de los dos dice "te quiero" primero cuando algo bueno nos pasa?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.romanticas, ['Yo lo digo primero', 'Tú lo dices primero']),
  _c('romanticas-conexion-romance-2', '¿Quién de los dos es más detallista con los pequeños gestos románticos?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.romanticas, ['Yo soy más detallista', 'Tú eres más detallista']),
  _c('romanticas-conexion-romance-3', '¿Quién de los dos piensa más en el otro durante el día sin confesarlo?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.romanticas, ['Yo pienso más', 'Tú piensas más']),
  // Conexión · Romance · alta
  _c('romanticas-conexion-romance-4', '¿Quién de los dos se pone más sentimental cuando hablamos del futuro juntos?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas, ['Yo me pongo más sentimental', 'Tú te pones más sentimental']),
  _c('romanticas-conexion-romance-5', '¿Quién de los dos siente más "mariposas" cuando nos vemos después de unos días?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas, ['Yo siento más mariposas', 'Tú sientes más mariposas']),
  _c('romanticas-conexion-romance-6', '¿Quién de los dos se enamoró primero de verdad?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.romanticas, ['Yo me enamoré primero', 'Tú te enamoraste primero']),
  // Conexión · Nostalgia · media
  _c('romanticas-conexion-nostalgia-1', '¿Quién de los dos recuerda mejor cómo nos conocimos?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.romanticas, ['Yo recuerdo mejor', 'Tú recuerdas mejor']),
  _c('romanticas-conexion-nostalgia-2', '¿Quién de los dos cuenta con más cariño las anécdotas de nuestros comienzos?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.romanticas, ['Yo las cuento con más cariño', 'Tú las cuentas con más cariño']),
  _c('romanticas-conexion-nostalgia-3', '¿Quién guarda más capturas o fotos de nuestros primeros meses?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.romanticas, ['Yo guardo más', 'Tú guardas más']),
  // Conexión · Nostalgia · alta
  _c('romanticas-conexion-nostalgia-4', '¿Quién de los dos se emociona más al revivir nuestros recuerdos?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas, ['Yo me emociono más', 'Tú te emocionas más']),
  _c('romanticas-conexion-nostalgia-5', '¿Quién de los dos extraña más los momentos que ya pasaron?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas, ['Yo los extraño más', 'Tú los extrañas más']),
  _c('romanticas-conexion-nostalgia-6', '¿Quién de los dos habría hecho el primer movimiento si no nos hubiéramos encontrado?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas, ['Yo lo habría hecho', 'Tú lo habrías hecho']),
  // Conexión · Futuro · media
  _c('romanticas-conexion-futuro-1', '¿Quién de los dos habla primero de los planes a futuro?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.romanticas, ['Yo hablo primero', 'Tú hablas primero']),
  _c('romanticas-conexion-futuro-2', '¿Quién de los dos imagina con más detalle cómo será nuestra vida en unos años?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.romanticas, ['Yo la imagino con más detalle', 'Tú la imaginas con más detalle']),
  _c('romanticas-conexion-futuro-3', '¿Quién de los dos propone más aventuras que todavía no hemos vivido?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.romanticas, ['Yo propongo más', 'Tú propones más']),
  // Conexión · Futuro · alta
  _c('romanticas-conexion-futuro-4', '¿Quién de los dos sueña más en grande con lo que construiremos?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas, ['Yo sueño más en grande', 'Tú sueñas más en grande']),
  _c('romanticas-conexion-futuro-5', '¿Quién de los dos tiene más claro el plan de vida de la pareja?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas, ['Yo lo tengo más claro', 'Tú lo tienes más claro']),
  _c('romanticas-conexion-futuro-6', '¿Quién de los dos se ilusiona más con la idea de envejecer juntos?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas, ['Yo me ilusiono más', 'Tú te ilusionas más']),
  // Conexión · Coqueteo · media
  _c('romanticas-conexion-coqueteo-1', '¿Quién de los dos es más coqueto/a sin darse cuenta?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.romanticas, ['Yo soy más coqueto/a', 'Tú eres más coqueto/a']),
  _c('romanticas-conexion-coqueteo-2', '¿Quién de los dos conquista con más frecuencia al otro con una mirada?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.romanticas, ['Yo conquisto más', 'Tú conquistas más']),
  _c('romanticas-conexion-coqueteo-3', '¿Quién de los dos hace primero el primer gesto cuando quiere atención?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.romanticas, ['Yo hago el primer gesto', 'Tú haces el primer gesto']),
  // Conexión · Coqueteo · alta
  _c('romanticas-conexion-coqueteo-4', '¿Quién de los dos pierde la concentración primero cuando el otro coquetea?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas, ['Yo pierdo primero', 'Tú pierdes primero']),
  _c('romanticas-conexion-coqueteo-5', '¿Quién de los dos tiene más "poder" para hacer sonrojar al otro?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas, ['Yo tengo más poder', 'Tú tienes más poder']),
  _c('romanticas-conexion-coqueteo-6', '¿Quién de los dos disfruta más que lo persigan un poquito?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.romanticas, ['Yo disfruto más', 'Tú disfrutas más']),
  // Conexión · Celebración · media
  _c('romanticas-conexion-celebracion-1', '¿Quién de los dos celebra más las pequeñas victorias de la relación?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas, ['Yo celebro más', 'Tú celebras más']),
  _c('romanticas-conexion-celebracion-2', '¿Quién de los dos hace más "mundo" con los aniversarios y fechas importantes?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas, ['Yo hago más mundo', 'Tú haces más mundo']),
  _c('romanticas-conexion-celebracion-3', '¿Quién de los dos se alegra primero por los logros del otro?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.romanticas, ['Yo me alegro primero', 'Tú te alegras primero']),
  // Conexión · Celebración · alta
  _c('romanticas-conexion-celebracion-4', '¿Quién de los dos daría un discurso más emotivo si tuviéramos que celebrar algo grande?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas, ['Yo daría el discurso', 'Tú darías el discurso']),
  _c('romanticas-conexion-celebracion-5', '¿Quién de los dos se emociona más fácil cuando brindamos por nosotros?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas, ['Yo me emociono más', 'Tú te emocionas más']),
  _c('romanticas-conexion-celebracion-6', '¿Quién de los dos está más orgulloso/a de la relación que hemos construido?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas, ['Yo estoy más orgulloso/a', 'Tú estás más orgulloso/a']),
  // Conexión · Diversión · media
  _c('romanticas-conexion-diversion-1', '¿Quién de los dos hace reír más al otro?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas, ['Yo hago reír más', 'Tú haces reír más']),
  _c('romanticas-conexion-diversion-2', '¿Quién de los dos es el más cursi de la pareja en secreto?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas, ['Yo soy más cursi', 'Tú eres más cursi']),
  _c('romanticas-conexion-diversion-3', '¿Quién de los dos se toma más en serio una cita y quién la improvisa?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.romanticas, ['Yo la preparo más', 'Tú la improvisas más']),
  // Conexión · Diversión · alta
  _c('romanticas-conexion-diversion-4', '¿Quién de los dos convierte más fácil un momento aburrido en uno inolvidable?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.romanticas, ['Yo lo convierto más fácil', 'Tú lo conviertes más fácil']),
  _c('romanticas-conexion-diversion-5', '¿Quién de los dos baila peor pero lo disfruta más?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.romanticas, ['Yo bailo peor y lo disfruto más', 'Tú bailas peor y lo disfrutas más']),
  _c('romanticas-conexion-diversion-6', '¿Quién de los dos aguantaría más tiempo una "cara de poker" antes de reírse?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.romanticas, ['Yo aguantaría más', 'Tú aguantarías más']),
  // Conexión · Conexión · media
  _c('romanticas-conexion-conexion-1', '¿Quién de los dos inicia más los abrazos?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.romanticas, ['Yo inicia los abrazos', 'Tú inicia los abrazos']),
  _c('romanticas-conexion-conexion-2', '¿Quién de los dos nota primero cuándo el otro tiene un mal día?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.romanticas, ['Yo lo noto primero', 'Tú lo notas primero']),
  _c('romanticas-conexion-conexion-3', '¿Quién de los dos escucha con más paciencia cuando el otro necesita desahogarse?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.romanticas, ['Yo escucho con más paciencia', 'Tú escuchas con más paciencia']),
  // Conexión · Conexión · alta
  _c('romanticas-conexion-conexion-4', '¿Quién de los dos necesita más la cercanía física para sentirse conectado/a?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.romanticas, ['Yo la necesito más', 'Tú la necesitas más']),
  _c('romanticas-conexion-conexion-5', '¿Quién de los dos entiende al otro sin que diga nada?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.romanticas, ['Yo te entiendo mejor', 'Tú me entiendes mejor']),
  _c('romanticas-conexion-conexion-6', '¿Quién de los dos se siente más "en casa" cuando estamos juntos?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.romanticas, ['Yo me siento más en casa', 'Tú te sientes más en casa']),

  // ════════════════════════════════════════════════════════════════════════
  // CALIENTES · Conexión
  // ════════════════════════════════════════════════════════════════════════
  // Conexión · Romance · media
  _c('calientes-conexion-romance-1', '¿Quién de los dos es el primero en buscar el contacto cuando estamos solos?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes, ['Yo busco primero', 'Tú buscas primero']),
  _c('calientes-conexion-romance-2', '¿Quién de los dos mantiene más tiempo una mirada sin apartarla?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes, ['Yo la mantengo más', 'Tú la mantienes más']),
  _c('calientes-conexion-romance-3', '¿Quién de los dos nota primero el "clic" cuando la cosa se pone íntima?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.calientes, ['Yo lo noto primero', 'Tú lo notas primero']),
  // Conexión · Romance · alta
  _c('calientes-conexion-romance-4', '¿Quién de los dos se toma más tiempo en los besos?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes, ['Yo me tomo más tiempo', 'Tú te tomas más tiempo']),
  _c('calientes-conexion-romance-5', '¿Quién de los dos propone primero llevarlo a un lugar más privado?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes, ['Yo lo propongo primero', 'Tú lo propones primero']),
  _c('calientes-conexion-romance-6', '¿Quién de los dos disfruta más de los momentos de tensión previos?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.calientes, ['Yo disfruto más', 'Tú disfrutas más']),
  // Conexión · Nostalgia · media
  _c('calientes-conexion-nostalgia-1', '¿Quién de los dos recuerda mejor el primer beso?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes, ['Yo lo recuerdo mejor', 'Tú lo recuerdas mejor']),
  _c('calientes-conexion-nostalgia-2', '¿Quién de los dos habla más de lo bien que estábamos en nuestros inicios?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes, ['Yo hablo más', 'Tú hablas más']),
  _c('calientes-conexion-nostalgia-3', '¿Quién de los dos extraña más la época de "no podíamos soltarnos"?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.calientes, ['Yo la extraño más', 'Tú la extrañas más']),
  // Conexión · Nostalgia · alta
  _c('calientes-conexion-nostalgia-4', '¿Quién de los dos tiene mejor memoria de los detalles de nuestras noches intensas?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes, ['Yo tengo mejor memoria', 'Tú tienes mejor memoria']),
  _c('calientes-conexion-nostalgia-5', '¿Quién de los dos revive con más intensidad los recuerdos íntimos cuando está solo/a?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes, ['Yo los revivo más', 'Tú los revives más']),
  _c('calientes-conexion-nostalgia-6', '¿Quién de los dos propone más seguido "volver a hacer lo de aquella vez"?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes, ['Yo lo propongo más', 'Tú lo propones más']),
  // Conexión · Futuro · media
  _c('calientes-conexion-futuro-1', '¿Quién de los dos fantasea más con escapadas solo para los dos?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes, ['Yo fantaseo más', 'Tú fantaseas más']),
  _c('calientes-conexion-futuro-2', '¿Quién de los dos planea más la "noche perfecta"?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes, ['Yo la planeo más', 'Tú la planeas más']),
  _c('calientes-conexion-futuro-3', '¿Quién de los dos habla más de lo que haríamos si estuviéramos solos todo un fin de semana?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.calientes, ['Yo hablo más', 'Tú hablas más']),
  // Conexión · Futuro · alta
  _c('calientes-conexion-futuro-4', '¿Quién de los dos propone más "sorprender al otro" en la intimidad?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes, ['Yo propongo más', 'Tú propones más']),
  _c('calientes-conexion-futuro-5', '¿Quién de los dos se imagina más el reencuentro después de unos días sin verse?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes, ['Yo me lo imagino más', 'Tú te lo imaginas más']),
  _c('calientes-conexion-futuro-6', '¿Quién de los dos llevaría la iniciativa en una escapada romántica improvisada?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.calientes, ['Yo llevaría la iniciativa', 'Tú llevarías la iniciativa']),
  // Conexión · Coqueteo · media
  _c('calientes-conexion-coqueteo-1', '¿Quién de los dos se emociona primero cuando la noche empieza a ponerse interesante?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.calientes, ['Yo me emociono primero', 'Tú te emocionas primero']),
  _c('calientes-conexion-coqueteo-2', '¿Quién de los dos lanza más indirectas antes de pasar a la acción?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.calientes, ['Yo lanzo más', 'Tú lanzas más']),
  _c('calientes-conexion-coqueteo-3', '¿Quién de los dos es mejor "provocando" sin tocarse?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.calientes, ['Yo soy mejor', 'Tú eres mejor']),
  // Conexión · Coqueteo · alta
  _c('calientes-conexion-coqueteo-4', '¿Quién de los dos hace durar más el momento antes del primer contacto?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes, ['Yo lo hago durar más', 'Tú lo haces durar más']),
  _c('calientes-conexion-coqueteo-5', '¿Quién de los dos susurra mejor los "detalles al oído"?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes, ['Yo susurro mejor', 'Tú susurras mejor']),
  _c('calientes-conexion-coqueteo-6', '¿Quién de los dos gana más cuando el juego se pone de provocaciones?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.calientes, ['Yo gano más', 'Tú ganas más']),
  // Conexión · Celebración · media
  _c('calientes-conexion-celebracion-1', '¿Quién de los dos celebra mejor los buenos momentos en la intimidad?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes, ['Yo celebro mejor', 'Tú celebras mejor']),
  _c('calientes-conexion-celebracion-2', '¿Quién de los dos elige mejor la canción que cierra una noche especial?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes, ['Yo elijo mejor', 'Tú eliges mejor']),
  _c('calientes-conexion-celebracion-3', '¿Quién de los dos alarga más los buenos momentos para que no terminen?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.calientes, ['Yo los alargo más', 'Tú los alargas más']),
  // Conexión · Celebración · alta
  _c('calientes-conexion-celebracion-4', '¿Quién de los dos se siente más "en la cima" después de un momento intenso?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes, ['Yo me siento más', 'Tú te sientes más']),
  _c('calientes-conexion-celebracion-5', '¿Quién de los dos presumiría más de la química que tenemos?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes, ['Yo presumiría más', 'Tú presumirías más']),
  _c('calientes-conexion-celebracion-6', '¿Quién de los dos repetiría sin dudar una noche como las nuestras?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes, ['Yo la repetiría', 'Tú la repetirías']),
  // Conexión · Diversión · media
  _c('calientes-conexion-diversion-1', '¿Quién de los dos se ríe primero cuando algo sale "mal" en la intimidad?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes, ['Yo me río primero', 'Tú te ríes primero']),
  _c('calientes-conexion-diversion-2', '¿Quién de los dos se toma menos en serio los momentos coquetos?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes, ['Yo me los tomo menos en serio', 'Tú te los tomas menos en serio']),
  _c('calientes-conexion-diversion-3', '¿Quién de los dos inventa los juegos más picantes?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.calientes, ['Yo los invento', 'Tú los inventas']),
  // Conexión · Diversión · alta
  _c('calientes-conexion-diversion-4', '¿Quién de los dos se atrevería primero con un reto atrevido sin pensarlo dos veces?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.calientes, ['Yo me atrevería primero', 'Tú te atreverías primero']),
  _c('calientes-conexion-diversion-5', '¿Quién de los dos lleva la cuenta de "quién gana" en nuestros juegos?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.calientes, ['Yo llevo la cuenta', 'Tú llevas la cuenta']),
  _c('calientes-conexion-diversion-6', '¿Quién de los dos aguantaría más tiempo un "reto de miradas" sin ceder?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.calientes, ['Yo aguantaría más', 'Tú aguantarías más']),
  // Conexión · Conexión · media
  _c('calientes-conexion-conexion-1', '¿Quién de los dos siente más la conexión en un simple roce?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.calientes, ['Yo la siento más', 'Tú la sientes más']),
  _c('calientes-conexion-conexion-2', '¿Quién de los dos lee mejor el "momento justo" del otro?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.calientes, ['Yo lo leo mejor', 'Tú lo lees mejor']),
  _c('calientes-conexion-conexion-3', '¿Quién de los dos es más de caricias suaves y quién de abrazos fuertes?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.calientes, ['Yo soy más de caricias', 'Tú eres más de abrazos']),
  // Conexión · Conexión · alta
  _c('calientes-conexion-conexion-4', '¿Quién de los dos necesita más "presencia" del otro para sentirse conectado/a?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.calientes, ['Yo necesito más presencia', 'Tú necesitas más presencia']),
  _c('calientes-conexion-conexion-5', '¿Quién de los dos se queda más tiempo en el "después" de un momento especial?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.calientes, ['Yo me quedo más', 'Tú te quedas más']),
  _c('calientes-conexion-conexion-6', '¿Quién de los dos siente que la química nos hace únicos/as?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.calientes, ['Yo lo siento más', 'Tú lo sientes más']),

  // ════════════════════════════════════════════════════════════════════════
  // DIVERTIDAS · Conexión
  // ════════════════════════════════════════════════════════════════════════
  // Conexión · Romance · media
  _c('divertidas-conexion-romance-1', '¿Quién de los dos diría frases de película romántica en la vida real?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.divertidas, ['Yo las diría', 'Tú las dirías']),
  _c('divertidas-conexion-romance-2', '¿Quién de los dos es más dramático/a en las discusiones tontas?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.divertidas, ['Yo soy más dramático/a', 'Tú eres más dramático/a']),
  _c('divertidas-conexion-romance-3', '¿Quién de los dos pondría el "aviso de novios empalagosos" en el carrito del super?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.divertidas, ['Yo lo pondría', 'Tú lo pondrías']),
  // Conexión · Romance · alta
  _c('divertidas-conexion-romance-4', '¿Quién de los dos escribiría una canción de amor y la mandaría por mensaje?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.divertidas, ['Yo la escribiría', 'Tú la escribirías']),
  _c('divertidas-conexion-romance-5', '¿Quién de los dos sería el que más "suspira" viendo una comedia romántica?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.divertidas, ['Yo suspiraría más', 'Tú suspirarías más']),
  _c('divertidas-conexion-romance-6', '¿Quién de los dos ha dicho "esto es tan nosotros" más veces en esta relación?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.divertidas, ['Yo lo he dicho más', 'Tú lo has dicho más']),
  // Conexión · Nostalgia · media
  _c('divertidas-conexion-nostalgia-1', '¿Quién de los dos cuenta mejor (y más exagerado) nuestras anécdotas?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas, ['Yo las cuento mejor', 'Tú las cuentas mejor']),
  _c('divertidas-conexion-nostalgia-2', '¿Quién de los dos recuerda más las "perlas" graciosas del otro?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas, ['Yo las recuerdo más', 'Tú las recuerdas más']),
  _c('divertidas-conexion-nostalgia-3', '¿Quién de los dos insiste más en repetir la misma anécdota de nuestros inicios?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.divertidas, ['Yo insisto más', 'Tú insistes más']),
  // Conexión · Nostalgia · alta
  _c('divertidas-conexion-nostalgia-4', '¿Quién de los dos lloraría de risa recordando el momento más tonto de la relación?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas, ['Yo lloraría de risa', 'Tú llorarías de risa']),
  _c('divertidas-conexion-nostalgia-5', '¿Quién de los dos exagera más cuando cuenta "la primera vez que nos conocimos"?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas, ['Yo exagero más', 'Tú exageras más']),
  _c('divertidas-conexion-nostalgia-6', '¿Quién de los dos propone más seguido revisar fotos viejas para reírse?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas, ['Yo propongo más', 'Tú propones más']),
  // Conexión · Futuro · media
  _c('divertidas-conexion-futuro-1', '¿Quién de los dos haría la lista de "cosas locas por hacer" para el futuro?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.divertidas, ['Yo haría la lista', 'Tú harías la lista']),
  _c('divertidas-conexion-futuro-2', '¿Quién de los dos propone más ideas descabelladas de vacaciones?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.divertidas, ['Yo propongo más', 'Tú propones más']),
  _c('divertidas-conexion-futuro-3', '¿Quién de los dos pensaría que "comprar una casa rodante" es una gran idea?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.divertidas, ['Yo lo pensaría', 'Tú lo pensarías']),
  // Conexión · Futuro · alta
  _c('divertidas-conexion-futuro-4', '¿Quién de los dos soñaría más con abrir un negocio absurdo juntos?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas, ['Yo soñaría más', 'Tú soñarías más']),
  _c('divertidas-conexion-futuro-5', '¿Quién de los dos planearía el "concurso de cocina" de la pareja?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas, ['Yo lo planearía', 'Tú lo planearías']),
  _c('divertidas-conexion-futuro-6', '¿Quién de los dos tendría la idea de aprender algo imposible "solo por reírnos"?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas, ['Yo tendría la idea', 'Tú tendrías la idea']),
  // Conexión · Coqueteo · media
  _c('divertidas-conexion-coqueteo-1', '¿Quién de los dos es peor coqueteando pero se cree mejor?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.divertidas, ['Yo soy peor', 'Tú eres peor']),
  _c('divertidas-conexion-coqueteo-2', '¿Quién de los dos usa los "apodos tiernos" más ridículos?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.divertidas, ['Yo uso más', 'Tú usas más']),
  _c('divertidas-conexion-coqueteo-3', '¿Quién de los dos intenta coquetear con "memes" y le sale mal?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.divertidas, ['Yo intento y me sale mal', 'Tú intentas y te sale mal']),
  // Conexión · Coqueteo · alta
  _c('divertidas-conexion-coqueteo-4', '¿Quién de los dos dice "uy, se me cayó algo para que me mires" más seguido?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.divertidas, ['Yo lo digo más', 'Tú lo dices más']),
  _c('divertidas-conexion-coqueteo-5', '¿Quién de los dos haría una "coreografía de conquista" ridícula?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.divertidas, ['Yo la haría', 'Tú la harías']),
  _c('divertidas-conexion-coqueteo-6', '¿Quién de los dos gana más el "concurso de guiños" de la pareja?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.divertidas, ['Yo gano más', 'Tú ganas más']),
  // Conexión · Celebración · media
  _c('divertidas-conexion-celebracion-1', '¿Quién de los dos celebraría un "logro" con una fiesta completamente exagerada?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.divertidas, ['Yo haría la fiesta', 'Tú harías la fiesta']),
  _c('divertidas-conexion-celebracion-2', '¿Quién de los dos inventa más "premios" para la pareja?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.divertidas, ['Yo invento más', 'Tú inventas más']),
  _c('divertidas-conexion-celebracion-3', '¿Quién de los dos aplaudiría más fuerte cuando el otro hace algo bien?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.divertidas, ['Yo aplaudiría más fuerte', 'Tú aplaudirías más fuerte']),
  // Conexión · Celebración · alta
  _c('divertidas-conexion-celebracion-4', '¿Quién de los dos daría el "discurso de aceptación" si nos dieran un premio a la pareja más divertida?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas, ['Yo daría el discurso', 'Tú darías el discurso']),
  _c('divertidas-conexion-celebracion-5', '¿Quién de los dos haría "podio" con la mano y todo cuando ganamos algo?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas, ['Yo haría el podio', 'Tú harías el podio']),
  _c('divertidas-conexion-celebracion-6', '¿Quién de los dos sacaría más fotos para "presumir" de nuestros logros?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas, ['Yo sacaría más fotos', 'Tú sacarías más fotos']),
  // Conexión · Diversión · media
  _c('divertidas-conexion-diversion-1', '¿Quién de los dos pone los "sonidos" más raros al imitar al otro?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.divertidas, ['Yo pongo los sonidos', 'Tú pones los sonidos']),
  _c('divertidas-conexion-diversion-2', '¿Quién de los dos haría el "reto del baile prohibido" en público?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.divertidas, ['Yo lo haría', 'Tú lo harías']),
  _c('divertidas-conexion-diversion-3', '¿Quién de los dos pierde primero en un juego de mesa y se enoja en broma?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.divertidas, ['Yo pierdo y me enojo', 'Tú pierdes y te enojas']),
  // Conexión · Diversión · alta
  _c('divertidas-conexion-diversion-4', '¿Quién de los dos tiene el "humor más tonto" y lo disfruta igual?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.divertidas, ['Yo tengo el humor más tonto', 'Tú tienes el humor más tonto']),
  _c('divertidas-conexion-diversion-5', '¿Quién de los dos se reiría más fuerte de un chiste malo?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.divertidas, ['Yo me reiría más fuerte', 'Tú te reirías más fuerte']),
  _c('divertidas-conexion-diversion-6', '¿Quién de los dos "inventa" más la letra de las canciones mientras canta?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.divertidas, ['Yo invento la letra', 'Tú inventas la letra']),
  // Conexión · Conexión · media
  _c('divertidas-conexion-conexion-1', '¿Quién de los dos dice la palabra "tontito/a" con más cariño?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.divertidas, ['Yo la digo más', 'Tú la dices más']),
  _c('divertidas-conexion-conexion-2', '¿Quién de los dos entiende mejor los "códigos" tontos de la pareja?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.divertidas, ['Yo los entiendo mejor', 'Tú los entiendes mejor']),
  _c('divertidas-conexion-conexion-3', '¿Quién de los dos se ríe de sus propios chistes aunque nadie más los entienda?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.divertidas, ['Yo me río de los míos', 'Tú te ríes de los tuyos']),
  // Conexión · Conexión · alta
  _c('divertidas-conexion-conexion-4', '¿Quién de los dos sabe exactamente cuándo el otro necesita un chiste?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.divertidas, ['Yo lo sé mejor', 'Tú lo sabes mejor']),
  _c('divertidas-conexion-conexion-5', '¿Quién de los dos hace que el otro se sienta "en su lugar seguro" cuando las cosas se ponen serias?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.divertidas, ['Yo te hago sentir seguro/a', 'Tú me haces sentir seguro/a']),
  _c('divertidas-conexion-conexion-6', '¿Quién de los dos dice "nosotros" con más orgullo?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.divertidas, ['Yo lo digo con más orgullo', 'Tú lo dices con más orgullo']),

  // ════════════════════════════════════════════════════════════════════════
  // GENERALES · Conexión
  // ════════════════════════════════════════════════════════════════════════
  // Conexión · Romance · media
  _c('generales-conexion-romance-1', '¿Quién de los dos es más expresivo/a con el cariño?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.generales, ['Yo soy más expresivo/a', 'Tú eres más expresivo/a']),
  _c('generales-conexion-romance-2', '¿Quién de los dos da los cumplidos más sinceros?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.generales, ['Yo doy más cumplidos', 'Tú das más cumplidos']),
  _c('generales-conexion-romance-3', '¿Quién de los dos piensa más en el otro cuando no están juntos?', Chapter.conexion, Emotion.romance, Intensity.media, QuestionCategory.generales, ['Yo pienso más', 'Tú piensas más']),
  // Conexión · Romance · alta
  _c('generales-conexion-romance-4', '¿Quién de los dos es más sensible a los gestos románticos del otro?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.generales, ['Yo soy más sensible', 'Tú eres más sensible']),
  _c('generales-conexion-romance-5', '¿Quién de los dos confía más en que esta relación tiene futuro?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.generales, ['Yo confío más', 'Tú confías más']),
  _c('generales-conexion-romance-6', '¿Quién de los dos es más de demostrar el amor con acciones que con palabras?', Chapter.conexion, Emotion.romance, Intensity.alta, QuestionCategory.generales, ['Yo lo demuestro con acciones', 'Tú lo demuestras con acciones']),
  // Conexión · Nostalgia · media
  _c('generales-conexion-nostalgia-1', '¿Quién de los dos guarda más recuerdos materiales de la relación?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.generales, ['Yo guardo más', 'Tú guardas más']),
  _c('generales-conexion-nostalgia-2', '¿Quién de los dos echa de menos más los primeros tiempos?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.generales, ['Yo los echo de menos más', 'Tú los echas de menos más']),
  _c('generales-conexion-nostalgia-3', '¿Quién de los dos se acuerda mejor de las fechas importantes?', Chapter.conexion, Emotion.nostalgia, Intensity.media, QuestionCategory.generales, ['Yo me acuerdo mejor', 'Tú te acuerdas mejor']),
  // Conexión · Nostalgia · alta
  _c('generales-conexion-nostalgia-4', '¿Quién de los dos se emociona más con las fotos y recuerdos viejos?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.generales, ['Yo me emociono más', 'Tú te emocionas más']),
  _c('generales-conexion-nostalgia-5', '¿Quién de los dos recuerda más detalles de los momentos que vivieron?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.generales, ['Yo recuerdo más detalles', 'Tú recuerdas más detalles']),
  _c('generales-conexion-nostalgia-6', '¿Quién de los dos siente más nostalgia cuando pasa el tiempo?', Chapter.conexion, Emotion.nostalgia, Intensity.alta, QuestionCategory.generales, ['Yo siento más nostalgia', 'Tú sientes más nostalgia']),
  // Conexión · Futuro · media
  _c('generales-conexion-futuro-1', '¿Quién de los dos piensa más en los planes a largo plazo?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.generales, ['Yo pienso más', 'Tú piensas más']),
  _c('generales-conexion-futuro-2', '¿Quién de los dos es más optimista con el futuro?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.generales, ['Yo soy más optimista', 'Tú eres más optimista']),
  _c('generales-conexion-futuro-3', '¿Quién de los dos toma más la iniciativa para planear cosas nuevas?', Chapter.conexion, Emotion.futuro, Intensity.media, QuestionCategory.generales, ['Yo tomo más la iniciativa', 'Tú tomas más la iniciativa']),
  // Conexión · Futuro · alta
  _c('generales-conexion-futuro-4', '¿Quién de los dos habla más de cómo será su vida dentro de diez años?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.generales, ['Yo hablo más', 'Tú hablas más']),
  _c('generales-conexion-futuro-5', '¿Quién de los dos se ilusiona más rápido con las ideas nuevas?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.generales, ['Yo me ilusiono más rápido', 'Tú te ilusionas más rápido']),
  _c('generales-conexion-futuro-6', '¿Quién de los dos tendría más claro el destino si pudiéramos viajar mañana?', Chapter.conexion, Emotion.futuro, Intensity.alta, QuestionCategory.generales, ['Yo lo tendría claro', 'Tú lo tendrías claro']),
  // Conexión · Coqueteo · media
  _c('generales-conexion-coqueteo-1', '¿Quién de los dos es más directo/a cuando quiere llamar la atención?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.generales, ['Yo soy más directo/a', 'Tú eres más directo/a']),
  _c('generales-conexion-coqueteo-2', '¿Quién de los dos se sonroja más fácil?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.generales, ['Yo me sonrojo más', 'Tú te sonrojas más']),
  _c('generales-conexion-coqueteo-3', '¿Quién de los dos hace los cumplidos de forma más inesperada?', Chapter.conexion, Emotion.coqueteo, Intensity.media, QuestionCategory.generales, ['Yo los hago más inesperado', 'Tú los haces más inesperado']),
  // Conexión · Coqueteo · alta
  _c('generales-conexion-coqueteo-4', '¿Quién de los dos sabe mejor cómo animar al otro con una frase?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.generales, ['Yo sé mejor', 'Tú sabes mejor']),
  _c('generales-conexion-coqueteo-5', '¿Quién de los dos usa más el humor para acercarse?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.generales, ['Yo uso más el humor', 'Tú usas más el humor']),
  _c('generales-conexion-coqueteo-6', '¿Quién de los dos es más "difícil de conquistar"?', Chapter.conexion, Emotion.coqueteo, Intensity.alta, QuestionCategory.generales, ['Yo soy más difícil', 'Tú eres más difícil']),
  // Conexión · Celebración · media
  _c('generales-conexion-celebracion-1', '¿Quién de los dos celebra más los logros cotidianos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.generales, ['Yo celebro más', 'Tú celebras más']),
  _c('generales-conexion-celebracion-2', '¿Quién de los dos se alegra más sinceramente por el otro?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.generales, ['Yo me alegro más', 'Tú te alegras más']),
  _c('generales-conexion-celebracion-3', '¿Quién de los dos recuerda más los buenos momentos que los malos?', Chapter.conexion, Emotion.celebracion, Intensity.media, QuestionCategory.generales, ['Yo recuerdo más los buenos', 'Tú recuerdas más los buenos']),
  // Conexión · Celebración · alta
  _c('generales-conexion-celebracion-4', '¿Quién de los dos se siente más orgulloso/a del otro?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.generales, ['Yo me siento más orgulloso/a', 'Tú te sientes más orgulloso/a']),
  _c('generales-conexion-celebracion-5', '¿Quién de los dos agradece más lo que el otro hace por la relación?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.generales, ['Yo agradezco más', 'Tú agradeces más']),
  _c('generales-conexion-celebracion-6', '¿Quién de los dos siente que hemos logrado más juntos de lo que imaginó?', Chapter.conexion, Emotion.celebracion, Intensity.alta, QuestionCategory.generales, ['Yo lo siento más', 'Tú lo sientes más']),
  // Conexión · Diversión · media
  _c('generales-conexion-diversion-1', '¿Quién de los dos tiene el humor más parecido al del otro?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.generales, ['Yo tengo el humor más parecido', 'Tú tienes el humor más parecido']),
  _c('generales-conexion-diversion-2', '¿Quién de los dos se ríe más fácil con cualquier cosa?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.generales, ['Yo me río más fácil', 'Tú te ríes más fácil']),
  _c('generales-conexion-diversion-3', '¿Quién de los dos hace más "payasadas" para alegrar al otro?', Chapter.conexion, Emotion.diversion, Intensity.media, QuestionCategory.generales, ['Yo hago más payasadas', 'Tú haces más payasadas']),
  // Conexión · Diversión · alta
  _c('generales-conexion-diversion-4', '¿Quién de los dos se aburre más rápido y lo disimula peor?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.generales, ['Yo me aburro más rápido', 'Tú te aburres más rápido']),
  _c('generales-conexion-diversion-5', '¿Quién de los dos convertiría cualquier plan simple en una aventura?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.generales, ['Yo lo convierto en aventura', 'Tú lo conviertes en aventura']),
  _c('generales-conexion-diversion-6', '¿Quién de los dos aguanta más sin reírse en los momentos serios?', Chapter.conexion, Emotion.diversion, Intensity.alta, QuestionCategory.generales, ['Yo aguanto más', 'Tú aguantas más']),
  // Conexión · Conexión · media
  _c('generales-conexion-conexion-1', '¿Quién de los dos necesita más tiempo a solas para cargar energía?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.generales, ['Yo necesito más', 'Tú necesitas más']),
  _c('generales-conexion-conexion-2', '¿Quién de los dos es más de hablar y quién de escuchar?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.generales, ['Yo hablo más', 'Tú hablas más']),
  _c('generales-conexion-conexion-3', '¿Quién de los dos capta antes el estado de ánimo del otro?', Chapter.conexion, Emotion.conexion, Intensity.media, QuestionCategory.generales, ['Yo lo capto antes', 'Tú lo captas antes']),
  // Conexión · Conexión · alta
  _c('generales-conexion-conexion-4', '¿Quién de los dos se siente más comprendido/a por el otro?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.generales, ['Yo me siento más comprendido/a', 'Tú te sientes más comprendido/a']),
  _c('generales-conexion-conexion-5', '¿Quién de los dos pone más de su parte cuando hay un malentendido?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.generales, ['Yo pongo más de mi parte', 'Tú pones más de tu parte']),
  _c('generales-conexion-conexion-6', '¿Quién de los dos valora más los silencios cómodos juntos?', Chapter.conexion, Emotion.conexion, Intensity.alta, QuestionCategory.generales, ['Yo los valoro más', 'Tú los valoras más']),

  // ════════════════════════════════════════════════════════════════════════
  // ROMÁNTICAS · Cierre
  // ════════════════════════════════════════════════════════════════════════
  _c('romanticas-cierre-romance-1', '¿Quién de los dos se lleva el crédito de que esta relación funcione?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.romanticas, ['Yo me llevo el crédito', 'Tú te llevas el crédito']),
  _c('romanticas-cierre-nostalgia-1', '¿Quién de los dos va a recordar más momentos de esta partida?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.romanticas, ['Yo los recordaré más', 'Tú los recordarás más']),
  _c('romanticas-cierre-celebracion-1', '¿Quién de los dos merece más un aplauso por esta noche?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.romanticas, ['Yo merezco más el aplauso', 'Tú mereces más el aplauso']),
  _c('romanticas-cierre-futuro-1', '¿Quién de los dos está más ilusionado/a con lo que viene?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.romanticas, ['Yo estoy más ilusionado/a', 'Tú estás más ilusionado/a']),
  _c('romanticas-cierre-recuerdo-1', '¿Quién de los dos guarda mejor los recuerdos (fotos, mensajes, entradas)?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.romanticas, ['Yo guardo mejor', 'Tú guardas mejor']),

  // ════════════════════════════════════════════════════════════════════════
  // CALIENTES · Cierre
  // ════════════════════════════════════════════════════════════════════════
  _c('calientes-cierre-romance-1', '¿Quién de los dos se queda con más ganas de más noches como esta?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.calientes, ['Yo me quedo con más ganas', 'Tú te quedas con más ganas']),
  _c('calientes-cierre-nostalgia-1', '¿Quién de los dos va a extrañar más el clima de esta noche?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.calientes, ['Yo lo extrañaré más', 'Tú lo extrañarás más']),
  _c('calientes-cierre-celebracion-1', '¿Quién de los dos daría más "luz verde" para repetir esto pronto?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.calientes, ['Yo daría la luz verde', 'Tú darías la luz verde']),
  _c('calientes-cierre-futuro-1', '¿Quién de los dos planea ya la próxima noche especial?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.calientes, ['Yo la planeo', 'Tú la planeas']),
  _c('calientes-cierre-recuerdo-1', '¿Quién de los dos recordará mejor esta noche cuando pase el tiempo?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.calientes, ['Yo la recordaré mejor', 'Tú la recordarás mejor']),

  // ════════════════════════════════════════════════════════════════════════
  // DIVERTIDAS · Cierre
  // ════════════════════════════════════════════════════════════════════════
  _c('divertidas-cierre-romance-1', '¿Quién de los dos se declara "ganador/a oficial" de esta partida?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.divertidas, ['Yo me declaro ganador/a', 'Tú te declaras ganador/a']),
  _c('divertidas-cierre-nostalgia-1', '¿Quién de los dos va a contar la mejor anécdota de esta noche?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.divertidas, ['Yo la contaré mejor', 'Tú la contarás mejor']),
  _c('divertidas-cierre-celebracion-1', '¿Quién de los dos haría la "celebración oficial" de terminar la partida?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.divertidas, ['Yo haría la celebración', 'Tú harías la celebración']),
  _c('divertidas-cierre-futuro-1', '¿Quién de los dos propondría la revancha con algo todavía más absurdo?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.divertidas, ['Yo propondría la revancha', 'Tú propondrías la revancha']),
  _c('divertidas-cierre-recuerdo-1', '¿Quién de los dos va a sacar más veces la frase "te acuerdas de esta partida"?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.divertidas, ['Yo la diré más veces', 'Tú la dirás más veces']),

  // ════════════════════════════════════════════════════════════════════════
  // GENERALES · Cierre
  // ════════════════════════════════════════════════════════════════════════
  _c('generales-cierre-romance-1', '¿Quién de los dos se lleva mejor esta noche para el recuerdo?', Chapter.cierre, Emotion.romance, Intensity.alta, QuestionCategory.generales, ['Yo me la llevo mejor', 'Tú te la llevas mejor']),
  _c('generales-cierre-nostalgia-1', '¿Quién de los dos se queda pensando más en lo que hablamos hoy?', Chapter.cierre, Emotion.nostalgia, Intensity.alta, QuestionCategory.generales, ['Yo me quedo pensando más', 'Tú te quedas pensando más']),
  _c('generales-cierre-celebracion-1', '¿Quién de los dos siente que hoy valió la pena más?', Chapter.cierre, Emotion.celebracion, Intensity.alta, QuestionCategory.generales, ['Yo lo siento más', 'Tú lo sientes más']),
  _c('generales-cierre-futuro-1', '¿Quién de los dos tiene más ganas de la próxima partida?', Chapter.cierre, Emotion.futuro, Intensity.alta, QuestionCategory.generales, ['Yo tengo más ganas', 'Tú tienes más ganas']),
  _c('generales-cierre-recuerdo-1', '¿Quién de los dos va a recordar mejor lo que se dijeron hoy?', Chapter.cierre, Emotion.recuerdo, Intensity.alta, QuestionCategory.generales, ['Yo lo recordaré mejor', 'Tú lo recordarás mejor']),
];

/// Constructor del lote de comparaciones: id `nue-comparacion-<prefijo>`,
/// `QuestionType.comparacion`, `QuestionSource.original` y `status: listo`.
GameQuestion _c(
  String prefix,
  String text,
  Chapter chapter,
  Emotion emotion,
  Intensity intensity,
  QuestionCategory category,
  List<String> options,
) =>
    GameQuestion(
      id: 'nue-comparacion-$prefix',
      text: text,
      chapter: chapter,
      emotion: emotion,
      intensity: intensity,
      category: category,
      type: QuestionType.comparacion,
      options: options,
      source: QuestionSource.original,
      status: QuestionStatus.listo,
    );
