# Banco V1 — Reporte de migración y cobertura

Fecha: agosto 2026 · Estado: banco jugable construido, validado con el motor real y conectado al gameplay local y online (`GamePlayScreen`). El modo local y el modo online usan el motor con dos modos de juego: **temático** (categoría fuerte) y **aleatorio** (motor libre). El flujo online se apoya en el puente `engineRounds` (el host genera una vez, el invitado decodifica); ya no queda código legacy de preguntas en el juego. El banco llega a **973 preguntas** con la sexta fase de contenido: **42 comodines de conexión** (`nue-comodin-conexion-*`) que abren la variedad mecánica a `QuestionType.comodin` en el capítulo Conexión.

## Objetivo

Migrar el banco de preguntas legacy (`lib/data/questions.dart`, intacto) al modelo
`GameQuestion` del nuevo motor de partidas, de forma incremental y sin tocar el motor:
las preguntas se clasifican SEMÁNTICAMENTE contra las celdas que el `MatchBuilder`
realmente genera. Las que no encajan no se fuerzan: quedan para revisión.

## Fuentes y archivos

| Archivo | Rol |
|---|---|
| `lib/features/game_engine/domain/enums/migration.dart` | `QuestionSource {legacy, original}`, `QuestionStatus {listo, needsReview, ambiguo, incompatible}` |
| `lib/features/game_engine/data/migrated_questions.dart` | 356 preguntas legacy clasificadas (ids `leg-*`) |
| `lib/features/game_engine/data/new_questions_v1.dart` | 18 preguntas nuevas (ids `nue-*`) solo para huecos reales |
| `lib/features/game_engine/data/thematic_questions_v1.dart` | 614 preguntas del lote temático (ids `nue-<categoria>-*`): 64 románticas, 90 calientes, 70 divertidas, 81 locas, 76 retos, 99 incómodas y 134 extremas |
| `lib/features/game_engine/data/thematic_voices_v1.dart` | 28 momentos de voz por categoría (ids `nue-voice-*`) para el desenlace temático |
| `lib/features/game_engine/data/comodin_questions_v1.dart` | 42 comodines de conexión (ids `nue-comodin-conexion-*`) que cambian la dinámica de la partida (acciones y momentos compartidos) |
| `lib/features/game_engine/data/question_bank_v1.dart` | `bancoV1Questions` (jugable) + `migradasPendientesV1` |
| `lib/features/game_engine/domain/models/game_round.dart` | campo `enforceCategory` (tema fuerte vs blando) |
| `lib/features/game_engine/domain/selectors/question_selector.dart` | escalera fuerte (temático) vs libre (aleatorio) |
| `lib/features/game_engine/engine/playable_match_builder.dart` | `buildEngineMatch` + `pickNoVoiceFallback` (desenlace sin audio) |
| `test/migrated_bank_test.dart` | estructura, coherencia con el motor, simulación de 40 partidas |
| `test/thematic_mode_test.dart` | modos de juego: pureza temática, variedad aleatoria, fallback sin voz |

## Totales

| Conjunto | Cantidad |
|---|---|
| `migratedQuestions` | 356 |
| — `listo` (entran al banco jugable) | 271 |
| — `needsReview` | 0 |
| — `incompatible` | 85 |
| — `ambiguo` | 0 |
| `newQuestionsV1` (todas `listo`) | 18 |
| `thematicQuestionsV1` (todas `listo`) | 614 |
| `thematicVoicesV1` (todas `listo`) | 28 |
| `comodinQuestionsV1` (todas `listo`) | 42 |
| **`bancoV1Questions`** | **973** |
| `migradasPendientesV1` | 85 |

## Recorrido jugable por capítulo

| Capítulo | Preguntas | Retos | Comparaciones | Comodines | Voz |
|---|---|---|---|---|---|---|
| Bienvenida | 71 | 6 | 0 | 0 | 0 |
| Calentamiento | 276 | 40 | 0 | 0 | 0 |
| Conexión | 506 | 55 | 18 | 42 | 0 |
| Momento especial | 0 | 0 | 0 | 0 | 38 |
| Cierre | 82 | 5 | 0 | 0 | 0 |

## Cobertura por celda (capítulo × emoción × intensidad)

Celdas que el motor usa (33) y preguntas `listo` disponibles en cada una. El
selector solo falla cuando una celda queda sin candidatas dentro de la partida;
el umbral razonable es ≥ 4 para que el recorrido no se repita ni se agote.

### Bienvenida (suave)
| Emoción | Cantidad |
|---|---|
| diversion | 42 |
| descubrimiento | 29 |

### Calentamiento (suave → media)
| Emoción | suave | media |
|---|---|---|
| descubrimiento | 28 | 52 |
| diversion | 23 | 41 |
| nostalgia | 30 | 33 |
| conexion | 32 | 37 |

### Conexión (media → alta)
| Emoción | media | alta |
|---|---|---|
| romance | 40 | 23 |
| nostalgia | 28 | 30 |
| futuro | 50 | 30 |
| coqueteo | 38 | 49 |
| celebracion | 28 | 20 |
| diversion | 27 | 30 |
| conexion | 61 | 52 |

Los recuentos de Conexión incluyen las 18 comparaciones (románticas/calientes)
y los 42 comodines repartidos +3/+3 por emoción: todo suma candidatas por celda,
independientemente del tipo mecánico.

### Momento especial (intensa, solo voz)
| Emoción | Legacy | Temáticas | Total |
|---|---|---|---|
| recuerdo | 3 | 7 | 10 |
| romance | 5 | 7 | 12 |
| futuro | 1 | 7 | 8 |
| celebracion | 1 | 7 | 8 |

### Cierre (alta)
| Emoción | Cantidad |
|---|---|
| romance | 18 |
| nostalgia | 21 |
| celebracion | 17 |
| futuro | 14 |
| recuerdo | 12 |

## Modos de juego (motor local y online)

`GamePlayScreen` usa el motor (`buildEngineMatch`) en local y en online:

- **Modo temático** (elegir 1+ categorías): `MatchBuilder` marca `enforceCategory` y
  el selector usa la escalera fuerte — N1 tema+emoción+intensidad+tipo → N2 tema+emoción+intensidad±1+tipo →
  N3 tema+emoción → N4 tema → N5 cualquier pregunta (solo si el capítulo no tiene nada del tema).
  El Momento especial cierra con una voz del tema elegido (`thematicVoicesV1`); si nadie quiere
  hablar, `pickNoVoiceFallback` reemplaza el desenlace por una pregunta escrita del mismo tema.
- **Modo aleatorio** (botón "Modo aleatorio"): sin preferencias; el motor libre genera las
  categorías del espacio y la escalera suave con transiciones emocionales coherentes. La emoción
  del espacio nunca se sacrifica para encontrar pregunta (N5 → espacio sin pregunta, no forzada).

Cobertura temática medida con el banco actual (10 partidas por categoría, % de preguntas del tema):

| Categoría | % del tema | Capítulos sin banco del tema |
|---|---|---|
| romanticas | 100% | — |
| calientes | 100% | — |
| divertidas | 100% | — |
| locas | 100% | — |
| generales | 100% | — |
| retos | 100% | — |
| incomodas | 100% | — |
| extremas | 100% | — |

El lote temático (`thematic_questions_v1.dart`) rellenó los huecos que antes dejaban a
`romanticas`, `calientes`, `divertidas` y `locas` por debajo del 100%: ahora tienen
preguntas del tema en los cuatro capítulos de conversación y el modo temático se juega
entero con el tema elegido. En una segunda tanda, `retos` e `incomodas` cerraron su
100%: los retos se tipan `QuestionType.reto` (el motor ya los admite en Bienvenida y
Cierre) y las incómodas cubren las celdas que el motor genera, con las "Descubrimiento ·
alta" reclasificadas a Calentamiento + media (descubrimiento no vive en Conexión/Cierre).
En la tercera tanda, `extremas` cerró su 100% con 104 preguntas (99 entregadas + 5 del
Cierre) y 4 voces propias del desenlace; sus "Descubrimiento · alta" también se
reclasificaron a Calentamiento + media. En la cuarta tanda (a partir de la simulación
de "sensación de usuario"), se completaron las 5 emociones que faltaban en el Conexión
de `extremas` (romance, futuro, coqueteo, celebracion y diversion, 6 preguntas cada una
a media y alta): antes el selector degradaba la emoción del espacio en ~18% de los
momentos y el arco central de la partida extremas se sentía plano; con el banco
completo, la emoción del espacio coincide con la pregunta el **100%** de las veces.

## Huecos detectados y cómo se taparon

La primera simulación de 40 partidas con el motor real mostró 88 espacios sin
pregunta repartidos en las 40 partidas. Celdas críticas (solo 1 pregunta legacy):

| Celda | Legacy | Nuevas creadas |
|---|---|---|
| bienvenida + descubrimiento + suave | 1 | 6 (`nue-bienvenida-descubrimiento-*`) |
| conexion + diversion (media y alta) | 1 y 1 | 3 y 2 (`nue-conexion-diversion-*`) |
| cierre + recuerdo + alta | 1 | 3 (`nue-cierre-recuerdo-*`) |
| calentamiento + conexion (suave y media) | 3 y 3 | 2 y 2 (`nue-calentamiento-conexion-*`) |

Además se corrigieron 4 preguntas mal clasificadas (`leg-romanticas-38, 43, 48,
69`): estaban en Conexión con emoción Descubrimiento, que el capítulo no admite;
se movieron a Calentamiento + Descubrimiento + media.

### Lote temático (`thematic_questions_v1.dart`)

Segunda, tercera, cuarta y quinta fase de contenido: 614 preguntas nuevas (64 románticas, 90
calientes, 70 divertidas, 81 locas, 76 retos, 99 incómodas y 134 extremas) repartidas
por las celdas del recetario de cada categoría (los cuatro capítulos, con emoción e
intensidad dentro del pool y la rampa del capítulo). Objetivo: que el modo temático se
juegue entero con el tema elegido. Resultado medido (10 partidas por categoría): las
ocho categorías (`romanticas`, `calientes`, `divertidas`, `locas`, `retos`, `incomodas`,
`extremas` y `generales`) pasan a **100%** de pureza temática. Las preguntas de `locas`
son conversacionales (no retos de acción), pero las de `retos` sí usan
`QuestionType.reto`: el motor se extendió para admitir `reto` en Bienvenida y Cierre.
Las `incomodas` y `extremas` "Descubrimiento · alta" se reclasificaron a
Calentamiento + media porque descubrimiento no está en el pool de Conexión/Cierre. En
la quinta fase (piloto de variedad mecánica B) se añadieron **18 comparaciones**
(`QuestionType.comparacion`, 9 románticas + 9 calientes) al final del bloque de
Conexión de cada tema, cada una con sus 2 opciones (`options`): ambos eligen y luego
se comparan. Las preguntas se crearon en su propio archivo para no mezclar el lote con
los huecos estructurales de V1.

El bloque legacy `needsReview` (67) también se resolvió en esta etapa: 66 pasaron a
`listo` (refuerzan el banco jugable) y 1 de `extremas` a `incompatible`; hoy no queda
ninguna pregunta en revisión.

En la sexta fase (variedad mecánica) se añadieron **42 comodines de conexión**
(`nue-comodin-conexion-*`, `QuestionType.comodin`, archivo propio
`comodin_questions_v1.dart`): 7 emociones × {media, alta} × 3 textos del capítulo
Conexión, categoría `generales` (sin preferencia temática: en modo temático solo
caen como último recurso del capítulo; en aleatorio compiten en igualdad). Cambian
la dinámica de la partida —acciones y momentos compartidos, no solo respuestas— y
abren la variedad mecánica a un cuarto tipo jugable. `GameChapter` ya admitía
`comodin` en Conexión, así que no hizo falta tocar el motor ni el selector.

## Simulación de 40 partidas (motor real)

Se ejecutó `MatchBuilder` + `DefaultQuestionSelector` +
`InMemoryQuestionRepository(bancoV1Questions)` con 40 semillas (1..40).

- Partidas con espacios vacíos: **0 / 40**
- Huecos totales: **0**
- Sin preguntas repetidas dentro de una misma partida (regla del selector).
- Determinismo: misma semilla produce la misma partida.

## Limitaciones conocidas y siguientes pasos

1. **Reutilización entre partidas**: cada partida usa 25 preguntas; con 973 en el
   banco (40 partidas × 25 = 1000 huecos), el reparto medio es ~1.03 usos por
   pregunta y la reutilización visible queda en el tramo final de las 40. Para
   "40 partidas sin sentirse repetidas" al 100% se necesitarían ~1000 preguntas.
   El banco V1 garantiza variedad dentro de cada partida; la ampliación es trabajo
   de contenido incremental (V2+).
2. **Momento especial escaso en aleatorio**: en modo aleatorio las voces legacy
   cubren las 4 emociones (recuerdo 3, romance 5, futuro 1, celebracion 1) pero
   `futuro` y `celebracion` se repetirán entre partidas. El modo temático no sufre
   esto: cada categoría con banco tiene sus 4 voces del clímax.
3. **`needsReview` resuelto**: el bloque legacy (67) pasó a `listo` (66, refuerzan
   el banco) e `incompatible` (1 de `extremas`); hoy no queda ninguna pregunta en
   revisión. La decisión pendiente de clasificación manual queda acotada a las 85
   `incompatible`.
4. **`incompatible` (85)**: casi todo el bloque `calientes` explícito (Coqueteo
   intensa no se genera en el motor actual), dilemas de `extremas` y confesiones
   que ponen a prueba la pareja. Fuera del juego V1 por decisión de diseño.
5. **Vulnerabilidad**: la emoción no está en el pool de ningún capítulo actual;
   las preguntas que la piden quedan en `incompatible` hasta que el motor tenga un
   tramo dedicado.
6. **Categoría `generales`**: las 6 categorías comentadas de legacy (viajes,
   familia, intimidad_profunda, futuro, confesiones, agradecimiento) se reactivaron
   como fuente mapeándolas a `generales` (el enum de categoría no las tiene). Es la
   única categoría con banco propio además de sus voces: los 42 comodines de
   conexión viven aquí.
   Las ocho categorías jugables (`romanticas`, `calientes`, `divertidas`, `locas`,
   `retos`, `incomodas`, `extremas` y `generales`) tienen banco y voces propias en
   el motor: el modo temático se juega al 100% con cualquiera de ellas.
7. **Banco experimental (`exp-*`)**: no forma parte de `bancoV1Questions`. El
   gameplay del motor ya usa `bancoV1Questions`; `experimental_questions.dart`
   queda solo para los tests del motor.
8. **Flujo online en el motor**: el modo online ya juega 100% con el motor. El host
   genera la partida una sola vez con `buildEngineMatch` y publica el recorrido en
   `engineRounds` (`saveEngineMatch`); el invitado lo reconstruye con
   `decodeEngineMatch` por `roomStream` sin generar localmente. El restart usa el
   mismo puente (`restartGame` → `buildOnlineRestartUpdate`) en una sola escritura
   atómica. Las comparaciones se juegan a dos dispositivos vía `comparisonP1/P2`.
   Se eliminaron los fallbacks legacy (`questions`, `saveQuestions`, restart legacy
   con `getRandomQuestions`): el campo `questions` ya no se escribe y no queda código
   legacy de preguntas activo en el flujo de juego.
9. **Monotonía mecánica (en mejora)**: el banco jugable tiene `conversacion`, `reto`,
   `voz`, `comparacion` (18, románticas/calientes de Conexión) y, desde la sexta
   fase, `comodin` (42, Conexión de `generales`). La variedad aún se concentra en
   el capítulo Conexión y por tema: románticas y calientes ≈ 85% conversación,
   retos ≈ 96% reto, `generales` es la única con comodines. Extender comparaciones
   y comodines al resto de temas y capítulos es trabajo de contenido para el V2.
