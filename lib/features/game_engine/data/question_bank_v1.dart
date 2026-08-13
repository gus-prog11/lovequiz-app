import '../domain/enums/migration.dart';
import '../domain/models/game_question.dart';
import 'comodin_questions_v1.dart';
import 'migrated_questions.dart';
import 'new_questions_v1.dart';
import 'thematic_questions_v1.dart';
import 'thematic_voices_v1.dart';

/// Banco V1 del nuevo motor de partidas.
///
/// Compone las preguntas jugables a partir de cuatro fuentes:
///
///  - `migratedQuestions`: banco legacy clasificado (solo entran al banco
///    jugable las marcadas `QuestionStatus.listo`);
///  - `newQuestionsV1`: preguntas nuevas (`nue-*`) creadas para tapar huecos
///    reales de celdas que el motor usa;
///  - `thematicQuestionsV1`: lote temático (`nue-<categoria>-*`) que sube la
///    cobertura del modo temático para `romanticas`, `calientes` y `divertidas`;
///  - `thematicVoicesV1`: momentos de voz del Momento especial por categoría
///    (`nue-voice-*`), para que el modo temático tenga desenlace de su tema;
///  - `comodinQuestionsV1`: comodines de conexión (`nue-comodin-conexion-*`)
///    que cambian la dinámica de la partida y abren la variedad mecánica a
///    `QuestionType.comodin` (acciones compartidas, no solo respuestas).
///
/// El banco jugable se expone como `bancoV1Questions`; el resto de preguntas
/// migradas (revisión/ambiguas/incompatibles) queda fuera del juego pero se
/// conserva en `migratedQuestions` para decisiones futuras. `docs/banco_v1_report.md`
/// documenta la cobertura, las celdas débiles y la simulación de 40 partidas.
final List<GameQuestion> bancoV1Questions = <GameQuestion>[
  ...migratedQuestions.where((q) => q.status == QuestionStatus.listo),
  ...newQuestionsV1,
  ...thematicQuestionsV1,
  ...thematicVoicesV1,
  ...comodinQuestionsV1,
];

/// Preguntas migradas pendientes de decisión manual (no juegan en V1).
final List<GameQuestion> migradasPendientesV1 = migratedQuestions
    .where((q) => q.status != QuestionStatus.listo)
    .toList();
