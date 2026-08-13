import 'dart:math';

import '../enums/emotion.dart';
import '../enums/intensity.dart';
import '../enums/question_category.dart';
import '../enums/question_type.dart';
import '../models/game_chapter.dart';
import '../models/game_round.dart';

/// Diseñador de conversaciones: construye la partida completa (recorrido
/// emocional) ANTES de asignar preguntas reales.
///
/// El documento Core GamePlay (§ "¿Cómo se construye una partida?") pide que
/// cada partida cuente una pequeña historia. El builder decide, para cada
/// espacio de la partida, qué emoción se quiere vivir, a qué intensidad, qué
/// categoría temática se prefiere y qué tipos de pregunta son válidos. Las
/// emociones avanzan con transiciones suaves (reglas en `Emotion.smoothNext`)
/// y la intensidad sube en rampa sin saltos bruscos. Es puro (sin Flutter ni
/// I/O) y recibe un `Random` inyectable para que los tests sean reproducibles.
class MatchBuilder {
  MatchBuilder({
    required this.chapters,
    this.preferredCategories = const [],
    Random? random,
  }) : _random = random ?? Random();

  /// Capítulos configurados para la partida, en orden.
  final List<GameChapter> chapters;

  /// Categorías temáticas preferidas por el jugador.
  ///
  /// Si no está vacío, la partida se juega en **modo temático**: la categoría
  /// de cada espacio se elige entre estas y se marca como restricción fuerte
  /// (`enforceCategory`) para que el selector la mantenga hasta el último
  /// recurso. Si está vacío, la partida se juega en **modo aleatorio**: cada
  /// espacio elige una categoría al azar como preferencia blanda y la
  /// escalera del selector la degrada igual que el resto de criterios.
  final List<QuestionCategory> preferredCategories;

  final Random _random;

  /// Genera la secuencia completa de espacios (una partida) para los
  /// capítulos configurados.
  ///
  /// Con la configuración por defecto produce 25 espacios: Bienvenida (5) →
  /// Calentamiento (6) → Conexión (8) → Momento especial (1) → Cierre (5). La
  /// rampa de intensidad es global y suave (1 → 2 → 3 → 4 → 3), sin cortes
  /// bruscos entre etapas.
  List<GameRound> build() {
    final rounds = <GameRound>[];
    Emotion? lastEmotion;

    for (final chapter in chapters) {
      final count = chapter.approximateQuestionCount;
      final usedInChapter = <Emotion>{};
      for (var i = 0; i < count; i++) {
        // El último espacio de una etapa que lo permite es el momento
        // especial: escaso, con voz garantizada y emoción elegida al azar
        // (todas las candidatas tienen la misma oportunidad, para que
        // Recuerdo pueda ganar pese a su peso bajo).
        final special = chapter.allowsSpecialMoments && i == count - 1;

        final emotion = _pickEmotion(
          chapter: chapter,
          lastEmotion: lastEmotion,
          special: special,
          usedInChapter: usedInChapter,
        );
        final intensity = _rampIntensity(
          chapter: chapter,
          index: i,
          total: count,
        );

        usedInChapter.add(emotion);

        rounds.add(
          GameRound(
            chapter: chapter.id,
            emotion: emotion,
            intensity: intensity,
            // Categoría preferida provisional: se elige al azar hasta que el
            // banco definitivo permita mapear categorías por capítulo/emoción.
            category: _pickCategory(),
            // Con preferencias el tema es fuerte (modo temático); sin ellas,
            // la categoría por espacio es una preferencia blanda (aleatorio).
            enforceCategory: preferredCategories.isNotEmpty,
            allowedTypes: special
                ? const [QuestionType.voz]
                : chapter.allowedTypes,
            isSpecial: special,
          ),
        );

        lastEmotion = emotion;
      }
    }

    return rounds;
  }

  /// Categoría temática preferida del espacio.
  ///
  /// En modo temático (hay preferencias) se elige uniformemente entre las
  /// categorías del jugador. En modo aleatorio todas las categorías
  /// participan por igual.
  QuestionCategory _pickCategory() {
    if (preferredCategories.isEmpty) {
      return QuestionCategory.values[_random.nextInt(
        QuestionCategory.values.length,
      )];
    }
    return preferredCategories[_random.nextInt(preferredCategories.length)];
  }

  /// Elige la emoción del espacio. No repite la emoción anterior (salvo que
  /// no haya alternativa) y prefiere las transiciones suaves definidas en
  /// `Emotion.smoothNext`: entre las emociones del pool que pueden seguir a
  /// la anterior, elige ponderadamente por `weight`. Si ninguna lo hace, cae
  /// al pool completo (fallback) para no bloquear la partida. En el momento
  /// especial todas las emociones del capítulo tienen la misma oportunidad.
  ///
  /// Cuando el capítulo activa `noEmotionRepeat`, además excluye las emociones
  /// ya usadas en el capítulo (`usedInChapter`) mientras queden alternativas;
  /// así el Cierre no repite emoción y termina con la variedad del Peak-End.
  Emotion _pickEmotion({
    required GameChapter chapter,
    required Emotion? lastEmotion,
    required bool special,
    required Set<Emotion> usedInChapter,
  }) {
    var pool = chapter.emotions.where((e) => e != lastEmotion).toList();
    if (chapter.noEmotionRepeat) {
      final remaining = pool
          .where((e) => !usedInChapter.contains(e))
          .toList();
      if (remaining.isNotEmpty) pool = remaining;
    }
    final candidates = pool.isNotEmpty ? pool : chapter.emotions;

    if (special) {
      return candidates[_random.nextInt(candidates.length)];
    }

    final smooth = lastEmotion == null
        ? candidates
        : candidates
              .where((e) => smoothTransitions[lastEmotion]!.contains(e))
              .toList();
    final effective = smooth.isNotEmpty ? smooth : candidates;
    return _weightedPick(effective);
  }

  /// Selección ponderada por `Emotion.weight` (frecuencia del documento).
  Emotion _weightedPick(List<Emotion> emotions) {
    final total = emotions.fold<double>(0, (sum, e) => sum + e.weight);
    var roll = _random.nextDouble() * total;
    for (final emotion in emotions) {
      roll -= emotion.weight;
      if (roll < 0) return emotion;
    }
    return emotions.last;
  }

  /// Rampa suave de intensidad dentro de la etapa: arranca en `minIntensity`
  /// y llega a `targetIntensity` en su último espacio.
  Intensity _rampIntensity({
    required GameChapter chapter,
    required int index,
    required int total,
  }) {
    if (total <= 1) return chapter.targetIntensity;
    final start = chapter.minIntensity.level;
    final end = chapter.targetIntensity.level;
    final level = start + ((end - start) * index / (total - 1)).round();
    return Intensity.values.firstWhere((i) => i.level == level);
  }
}

/// Escala la partida para que tenga exactamente `totalRounds` espacios
/// conservando el arco emocional completo.
///
/// El Momento especial (el pico de la partida) siempre ocupa 1 espacio y los
/// demás capítulos se reducen proporcionalmente a su tamaño base. Las
/// fracciones se reparten con el método del resto mayor para que la suma final
/// sea exacta. Si `totalRounds` es mayor o igual al recorrido base, devuelve
/// los capítulos intactos.
List<GameChapter> scaleChaptersForRounds(
  List<GameChapter> chapters,
  int totalRounds,
) {
  final total = chapters.fold<int>(
    0,
    (sum, c) => sum + c.approximateQuestionCount,
  );
  if (totalRounds <= 0 || totalRounds >= total) return chapters;

  final special = chapters.where((c) => c.allowsSpecialMoments).toList();
  final normal = chapters.where((c) => !c.allowsSpecialMoments).toList();

  // Mínimo viable: 1 espacio por capítulo + el momento especial.
  final min = normal.length + special.length;
  final target = totalRounds < min ? min : totalRounds;

  final remaining = target - special.length;
  final normalBase = normal.fold<int>(
    0,
    (sum, c) => sum + c.approximateQuestionCount,
  );

  // Resto mayor: piso + repartir el déficit entre las fracciones más grandes.
  final raw = normal
      .map((c) => c.approximateQuestionCount * remaining / normalBase)
      .toList();
  final floors = raw.map((r) => r.floor()).toList();
  var deficit = remaining - floors.reduce((a, b) => a + b);
  final order = List<int>.generate(raw.length, (i) => i)
    ..sort((a, b) => (raw[b] - floors[b]).compareTo(raw[a] - floors[a]));
  for (var i = 0; i < order.length && deficit > 0; i++) {
    floors[order[i]]++;
    deficit--;
  }

  final scaled = <GameChapter>[];
  var i = 0;
  for (final c in chapters) {
    if (c.allowsSpecialMoments) {
      scaled.add(c.withCount(1));
    } else {
      scaled.add(c.withCount(floors[i]));
      i++;
    }
  }
  return scaled;
}
