# Banco V1 — Revisión cualitativa (7 criterios)

Fecha: agosto 2026 · Estado: revisión completada sobre `bancoV1Questions` (865 preguntas),
jugable y conectado al motor. **Actualización: las correcciones se aplicaron al banco**
(fecha posterior a la revisión); este documento conserva el diagnóstico original y al final
se describe qué se corrigió y con qué regla.

## Metodología

- Lectura completa del dump del banco (`bank_dump.tsv`, 865 líneas).
- Detección automática de duplicados y de pares similares con bigram-Jaccard
  (umbrales 0.72, 0.50 y 0.35).
- Validación automática de emoción e intensidad contra las reglas del capítulo
  (`GameChapter.forChapter`): pool de emociones e rango de intensidad.
- Revisión cualitativa del contenido para criterios no automatizables
  (conversación, propósito, naturalidad).

## Criterio 1 — Duplicados: ✅ sin problemas

| Verificación | Resultado |
|---|---|
| IDs duplicados | 0 |
| Textos duplicados exactos | 0 |

## Criterio 2 — Preguntas demasiado parecidas: ⚠️ 81 pares ≥ 0.35 sim

A partir de sim ≥ 0.72 solo hay 2 pares; el problema real son **familias de plantilla** que
abusan del mismo esqueleto con una palabra distinta. Las familias principales:

### 2.1 "¿Qué parte de nuestra relación te hace sentir más X?" (crítica)

Misma plantilla exacta, cambia solo la emoción objetivo:

| ID | Texto | Emoción |
|---|---|---|
| `nue-romanticas-conexion-romance-1` | ¿Qué parte de nuestra relación te hace sentir más querido/a? | romance |
| `nue-calientes-conexion-celebracion-5` | ¿Qué parte de nuestra relación te hace sentir más deseado/a? | celebracion |
| `nue-calientes-cierre-celebracion-2` | ¿Qué parte de nuestra relación te hace sentir más orgulloso/a de lo que tenemos? | celebracion |
| `nue-incomodas-conexion-conexion-15` | ¿Qué parte de nuestra relación te hace sentir más vulnerable? | conexion |

Mismo prefijo "¿Qué parte de nuestra relación...?" con finales distintos:

| ID | Texto |
|---|---|
| `nue-extremas-calentamiento-conexion-5` | ¿Qué parte de nuestra relación te gustaría que nunca cambiara? |
| `nue-extremas-conexion-conexion-11` | ¿Qué parte de nuestra relación te da más miedo perder? |
| `nue-incomodas-calentamiento-conexion-2` | ¿Qué parte de nuestra relación te costó más acostumbrarte a compartir? |
| `nue-incomodas-calentamiento-conexion-8` | ¿Qué cosa de nuestra relación te da miedo perder algún día? |
| `nue-incomodas-conexion-conexion-22` | ¿Qué parte de nuestra historia te daría más miedo perder? |

### 2.2 "¿Qué momento de nuestra historia te gustaría volver a vivir X?"

| ID | Texto |
|---|---|
| `nue-cierre-recuerdo-1` | ¿Qué momento de nuestra historia te gustaría volver a vivir tal cual? |
| `nue-divertidas-conexion-nostalgia-3` | ...volver a vivir solamente para reírnos otra vez? |
| `nue-locas-cierre-nostalgia-2` | ...volver a vivir aunque supieras que probablemente terminaría siendo un desastre? |
| `nue-calientes-calentamiento-nostalgia-6` | ¿Qué momento de nuestra historia repetirías exactamente como ocurrió? |
| `nue-calientes-cierre-nostalgia-3` | ¿Qué momento nuestro te gustaría volver a vivir una última vez exactamente como ocurrió? |
| `nue-romanticas-calentamiento-nostalgia-3` | ¿Qué momento de nuestra relación te gustaría poder volver a mirar exactamente como ocurrió? |
| `nue-retos-conexion-nostalgia-3` | ¿Qué momento de su relación le gustaría volver a experimentar exactamente como ocurrió? |

### 2.3 "¿Qué es lo que más te gusta de X?"

| ID | Texto |
|---|---|
| `leg-romanticas-2` | ¿Qué es lo que más te gusta de nuestra relación? |
| `leg-voice-2` | Dile a tu pareja qué es lo que más te gusta de ella. |
| `nue-calientes-conexion-celebracion-4` | ¿Qué es lo que más te gusta de nuestra química cuando estamos solos? |
| `nue-calientes-conexion-romance-5` | ¿Qué es lo que más te gusta de cómo somos cuando estamos completamente solos? |
| `nue-calientes-cierre-celebracion-1` | ¿Qué es lo que más te gusta de la química que hemos construido juntos? |

### 2.4 Pares casi idénticos (sim ≥ 0.5) más relevantes

| ID A | ID B | sim |
|---|---|---|
| `nue-divertidas-conexion-coqueteo-3` (forma ridícula de coquetear) | `nue-locas-conexion-coqueteo-1` (forma completamente absurda) | 0.64 |
| `nue-calientes-calentamiento-conexion-5` (contacto físico) | `nue-calientes-conexion-conexion-1` (cercanía física) | 0.57 |
| `nue-incomodas-conexion-conexion-14` (miedo del futuro, contado) | `nue-extremas-conexion-futuro-1` (miedo del futuro, dicho en voz alta) | 0.58 |
| `nue-calientes-conexion-diversion-5` (debilidad coqueteando) | `nue-divertidas-conexion-coqueteo-5` (debilidad provocando) | 0.67 |
| `nue-romanticas-conexion-conexion-1` (aprendido el uno del otro) | `nue-extremas-calentamiento-conexion-7` (aprendido el uno del otro) | 0.67 |
| `nue-divertidas-conexion-celebracion-5` (celebración tan exagerada que...) | `nue-locas-conexion-celebracion-5` (celebración tan exagerada que...) | 0.53 |
| `nue-voice-divertidas-recuerdo` (anécdota más graciosa) | `nue-voice-locas-recuerdo` (anécdota más absurda) | 0.62 |
| `nue-divertidas-calentamiento-conexion-4` (absurda... buen recuerdo) | `nue-locas-calentamiento-conexion-3` (absurda... buen recuerdo) | 0.56 |
| `nue-calientes-calentamiento-nostalgia-2` (chispa) | `nue-calientes-conexion-nostalgia-2` (química) | 0.56 |
| `nue-calientes-conexion-futuro-5` (recuerdo favorito) | `nue-calientes-cierre-futuro-2` (recuerdo favorito) | 0.63 |
| `leg-divertidas-32` (momento más torpe) | `leg-divertidas-33` (momento más vergonzoso conmigo) | 0.50 |
| `nue-incomodas-calentamiento-nostalgia-10` (error del pasado, hoy) | `nue-extremas-calentamiento-nostalgia-9` (error de tu pasado, conmigo) | 0.46 |
| `nue-locas-calentamiento-descubrimiento-4` (experiencia fuera de lo común) | `nue-extremas-calentamiento-diversion-10` (experiencia extrema, conmigo) | 0.47 |
| `nue-divertidas-conexion-diversion-4` (1 hora, sin consecuencias) | `nue-locas-conexion-diversion-4` (1 hora, sin preocupaciones) | ~0.35 |

## Criterio 3 — Emoción incorrecta: ⚠️ 1 clara + bordeline

**Validación automática contra el pool del capítulo: 0 violaciones.** Todas las emociones
etiquetadas pertenecen al capítulo donde vive la pregunta. Cualitativamente:

### Claras

- `nue-calientes-conexion-celebracion-5`: "¿Qué parte de nuestra relación te hace sentir
  más **deseado/a**?" está etiquetada `celebracion`; el contenido es deseo/atracción →
  debería ser `coqueteo` (o `romance`), no `celebracion`.

### Bordeline (revisar)

- `leg-voice-6`: "Dile algo que nunca le hayas dicho pero piensas a menudo." etiquetada
  `recuerdo`; es más confesión/`romance` que recuerdo.
- `leg-romanticas-42`: "Si tuvieras que elegir solo una cosa de mí para no cambiarla,
  ¿cuál sería?" etiquetada `romance`; podría ser `conexion`/`celebracion`.
- `leg-romanticas-27`: "¿Conoces alguna canción que defina nuestra relación?" etiquetada
  `nostalgia`; podría ser `conexion`.

## Criterio 4 — Intensidad incorrecta: ⚠️ 0 automáticas, varias cualitativas

**Rangos de intensidad del capítulo respetados al 100%** (validación automática). El
problema es cualitativo: temas con carga emocional alta colocados en Calentamiento
(media), donde la rampa aún es ligera.

### Calentamiento con temas pesados (media)

| ID | Texto |
|---|---|
| `nue-incomodas-calentamiento-conexion-9` | ¿Hay algo que necesites más de mí pero te cuesta pedírmelo? |
| `nue-incomodas-calentamiento-conexion-11` | ¿Qué tema entre nosotros te cuesta más hablar? |
| `nue-incomodas-calentamiento-conexion-12` | ¿Alguna vez has fingido estar bien conmigo cuando en realidad no lo estabas? |
| `nue-incomodas-calentamiento-conexion-14` | ¿Hay algo que alguna vez hayas querido decirme pero decidiste guardártelo? |
| `nue-incomodas-calentamiento-nostalgia-14` | ¿Qué versión de ti mismo extrañas aunque sabes que ya no quieres volver a ser esa persona? |
| `nue-extremas-calentamiento-conexion-14` | ¿Qué cosa deberíamos hablar más antes de que se convierta en un problema? |
| `nue-extremas-calentamiento-conexion-16` | ¿Qué podría hacer que empezaras a sentir distancia conmigo? |
| `nue-extremas-calentamiento-conexion-17` | ¿Qué cosa nunca deberíamos permitir que se vuelva normal entre nosotros? |
| `nue-extremas-calentamiento-conexion-18` | ¿Qué tema importante sobre nuestro futuro todavía no hemos hablado suficientemente? |
| `leg-romanticas-46` | ¿Crees que tu infancia ha influido en cómo amas? |

Contraste: estas preguntas son de tono similar a las `conexion · alta` de `incomodas`
(p. ej. `nue-incomodas-conexion-conexion-*`), que sí están en Conexión. Conviene subirlas
de capítulo/intensidad o suavizar el texto.

## Criterio 5 — No genera conversación: ⚠️ preferencias A/B y menús

Preguntas que se responden con una palabra o un "A/B" y no invitan a desarrollarse:

| ID | Texto | Motivo |
|---|---|---|
| `leg-calientes-69` | ¿Prefieres los besos lentos o los desesperados? | A/B; además casi duplicada de la 78 |
| `leg-calientes-78` | ¿Prefieres caricias lentas o besos apasionados? | A/B; casi duplicada de la 69 |
| `leg-viajes-2` | ¿Prefieren vacaciones de playa, montaña o ciudad? | menú, respuesta corta |
| `leg-viajes-7` | ¿Viajarían en mochila por el mundo juntos o prefieren lujo? | A/B |
| `leg-viajes-11` | ¿Prefieren un viaje planeado al detalle o la aventura espontánea? | A/B |
| `leg-viajes-13` | ¿Qué tipo de alojamiento prefieren: hostel, hotel, o glamping? | menú |
| `leg-viajes-15` | ¿Qué maleta no puede faltar en sus viajes? | respuesta corta |
| `leg-divertidas-7` | ¿Quién de los dos ronca más? | respuesta corta (no desarrolla) |
| `leg-divertidas-11` | ¿Quién ganaría en una pelea de almohadas? | respuesta corta |
| `leg-divertidas-31` | ¿Qué superpoder te gustaría tener? | genérica, no involucra a la pareja |
| `leg-divertidas-40` | ¿Cuál es el peor chiste que sabes contar? | invita a contar un chiste, no a conversar |
| `nue-retos-bienvenida-descubrimiento-1` | Por turnos, di una palabra y construyan juntos una historia absurda. | actividad, no conversación |

## Criterio 6 — Incómodas sin propósito: ⚠️ bloque extremas + cierre

Preguntas que generan incomodidad (miedo, pérdida, ruptura, muerte) sin que el recorrido
del juego prepare ese espacio ni tenga un propósito de cierre emocional claro:

| ID | Texto | Por qué no tiene propósito claro |
|---|---|---|
| `nue-extremas-conexion-conexion-10` | ¿Qué tendría que pasar para que consideraras terminar nuestra relación? | rompe el juego; no prepara la respuesta |
| `nue-extremas-conexion-conexion-14` | ¿Qué cosa nunca aceptarías dentro de nuestra relación, aunque eso significara terminarla? | idem |
| `nue-extremas-conexion-conexion-18` | Si algún día nuestra relación terminara, ¿qué te gustaría que nunca olvidáramos de nosotros? | introduce la ruptura sin contexto |
| `nue-incomodas-cierre-nostalgia-1` | ¿A quién te hubiera gustado pedirle perdón antes de que fuera demasiado tarde? | sugiere muerte/irreversible |
| `nue-extremas-conexion-nostalgia-1` | ¿Qué persona te gustaría poder volver a ver para decirle algo que nunca dijiste? | implica fallecido |
| `nue-extremas-conexion-conexion-19` | Si supieras con absoluta certeza que nuestra relación puede superar cualquier dificultad, ¿qué conversación pendiente tendrías conmigo hoy? | aunque busca facilitar, la premisa es forzada y carga la respuesta |

Nota: algunas incómodas sí tienen propósito (p. ej. límites, conflictos, peticiones:
`nue-incomodas-conexion-conexion-16`, `-20`, `nue-extremas-conexion-conexion-2`). La lista
de arriba son las que generan incomodidad **sin** entregar un recurso.

## Criterio 7 — Artificiales: ⚠️ construcciones recargadas/AI-sonantes

Preguntas con redacción convolucrada, premisas confusas o abstracción excesiva que se
sienten generadas en serie:

| ID | Texto | Problema |
|---|---|---|
| `nue-romanticas-conexion-diversion-4` | Si mañana apareciéramos en otro país sin equipaje y solo pudiéramos llevar una cosa de nuestra relación, ¿qué llevarías? | "una cosa de nuestra relación" es abstracto/confuso |
| `nue-extremas-calentamiento-descubrimiento-12` | ¿Cuál es el miedo más grande que tienes sobre convertirte en la persona que quieres ser? | abstracción filosófica, AI-sonante |
| `nue-extremas-calentamiento-descubrimiento-17` | ¿Qué miedo podría impedirte construir la vida que realmente quieres? | idem |
| `nue-extremas-calentamiento-descubrimiento-21` | ¿Qué perderías de ti mismo si intentaras convertirte en la persona que los demás esperan? | idem |
| `nue-extremas-conexion-conexion-19` | Si supieras con absoluta certeza... | doble condicional recargado |
| `nue-divertidas-conexion-diversion-4` | Si durante una hora pudiéramos hacer cualquier cosa sin consecuencias y solo para divertirnos, ¿qué haríamos? | redundante ("sin consecuencias" + "solo para divertirnos") y casi igual a locas |
| `nue-locas-conexion-diversion-4` | Si durante una hora pudiéramos hacer cualquier locura inofensiva sin preocuparnos por lo que pensaran los demás, ¿qué haríamos? | casi duplicada de la anterior |
| `nue-divertidas-calentamiento-descubrimiento-3` | ¿Qué opinión tienes sobre algo completamente absurdo que defenderías como si fuera importantísimo? | perífrasis recargada |
| `nue-extremas-calentamiento-conexion-18` | ¿Qué tema importante sobre nuestro futuro todavía no hemos hablado suficientemente? | tono administrativo |
| `nue-divertidas-calentamiento-conexion-5` | ¿Qué crees que hace que podamos divertirnos incluso cuando no estamos haciendo nada especial? | abstracta y de doble negación |
| `nue-retos-calentamiento-diversion-5` | Inventen una regla absurda que tendría que existir si ustedes gobernaran el mundo. | premisa recargada |

## Resumen

| Criterio | Resultado |
|---|---|
| 1. Duplicados | ✅ 0 |
| 2. Demasiado parecidas | ⚠️ 81 pares ≥0.35; 3 familias de plantilla críticas |
| 3. Emoción incorrecta | ⚠️ 0 automáticas; 1 clara (`nue-calientes-conexion-celebracion-5`) |
| 4. Intensidad incorrecta | ⚠️ 0 automáticas; ~10 cualitativas (Calentamiento pesado) |
| 5. No genera conversación | ⚠️ ~12 A/B, menús y actividades |
| 6. Incómodas sin propósito | ⚠️ 6 del bloque extremas/cierre |
| 7. Artificiales | ⚠️ ~11 redacciones recargadas |

## Siguientes pasos propuestos (pendientes de decisión)

1. Acordar qué criterios se corrigen en el banco y con qué regla (p. ej. reescribir,
   subir de capítulo, marcar `needsReview`).
2. Para las familias de plantilla (2.1–2.3), elegir 1–2 representantes y reescribir o
   eliminar el resto.
3. Corregir la emoción de `nue-calientes-conexion-celebracion-5` → `coqueteo`.
4. Subir de capítulo/intensidad las incómodas pesadas de Calentamiento o suavizar su
   texto.
5. Reescribir las artificiales y las A/B para que abran conversación.
6. Ajustar los tests que validan estructura/cobertura si cambian los metadatos
   (`test/migrated_bank_test.dart`, `test/thematic_mode_test.dart`).

---

## ✅ Correcciones aplicadas

Aplicadas al banco jugable, manteniendo **siempre** el conteo de 865 preguntas y los
metadatos (capítulo/emoción/intensidad/tipo) dentro de lo que validan los tests. La regla
fue: **no eliminar, no mover de capítulo** (rompería la simulación y el conteo exacto);
**reescribir texto y ajustar emociones** cuando fuera posible.

| Criterio | Qué se hizo |
|---|---|
| 3. Emoción incorrecta | `nue-calientes-conexion-celebracion-5` → emoción `coqueteo` (renombrada a `calientes-conexion-coqueteo-6` para respetar la convención del id) y texto reescrito: "¿Qué hago que te hace sentir deseado/a incluso sin decir una palabra?" |
| 4. Incómodas pesadas de Calentamiento | 10 preguntas reescritas con tono más ligero y conversacional (mantienen capítulo/emoción/intensidad), p. ej. `incomodas-calentamiento-conexion-9`, `-11`, `-12`, `-14`, `incomodas-calentamiento-nostalgia-14`, `extremas-calentamiento-conexion-14/16/17/18` y `leg-romanticas-46`. |
| 5. A/B, menús y actividades | 12 preguntas reescritas para abrir conversación (p. ej. `leg-calientes-70`, `leg-calientes-78`, `leg-viajes-2/7/11/13/15`, `leg-divertidas-7/11/31/40`). |
| 6. Incómodas sin propósito | 6 preguntas reescritas con recurso constructivo (límites, cierre de cuentas, momentos a proteger): `extremas-conexion-conexion-10/14/18/19`, `incomodas-cierre-nostalgia-1`, `extremas-conexion-nostalgia-1`. |
| 7. Artificiales | 11 preguntas simplificadas (doble condicional, perífrasis y abstracción reducidos): `romanticas-conexion-diversion-4`, `extremas-calentamiento-descubrimiento-12/17/21`, `divertidas-calentamiento-descubrimiento-3`, `divertidas-calentamiento-conexion-5`, `divertidas/locas-conexion-diversion-4`, `retos-calentamiento-diversion-5` y el suavizado de `extremas-calentamiento-conexion-18`. |
| 2. Familias de plantilla | Todas las variantes de las familias 2.1–2.3 reescritas con giros propios (manteniendo un representante por familia donde el texto era el mejor), y se afinaron los pares ≥0.5 restantes hasta **0 pares**. |

**Resultado medible** (script `test/_analysis_questions_test.dart`, bigram-Jaccard ≥0.5):

- Antes: 81 pares ≥0.35 · 16 pares ≥0.5.
- Después: **0 pares ≥0.5**, `idDups=0`, `textDups=0`, total **865** intacto.

**Validación:** `flutter test` completo en verde (82/82), incluidos `test/migrated_bank_test.dart`
(estructura, coherencia con el motor y simulación de 40 partidas) y
`test/thematic_mode_test.dart`.
