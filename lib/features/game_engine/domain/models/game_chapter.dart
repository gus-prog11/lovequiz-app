import '../enums/chapter.dart';
import '../enums/emotion.dart';
import '../enums/intensity.dart';
import '../enums/question_type.dart';

/// Plantilla de un capítulo (etapa) de la partida.
///
/// Define qué se busca conseguir en la etapa (`goal`), cuántos espacios
/// ocupa aproximadamente, qué emociones predominan, la intensidad a la que
/// debe llegar la rampa y qué tipos de pregunta son válidos. `MatchBuilder`
/// lo usa para diseñar el recorrido emocional antes de asignar preguntas.
class GameChapter {
  final Chapter id;
  final Duration duration;

  /// Objetivo psicológico de la etapa (qué se quiere lograr).
  final String goal;

  /// Cantidad aproximada de espacios/preguntas de la etapa.
  final int approximateQuestionCount;

  /// Pool de emociones válidas para esta etapa.
  final List<Emotion> emotions;
  final Intensity minIntensity;
  final Intensity maxIntensity;

  /// Intensidad a la que la rampa de la etapa debe llegar al final.
  final Intensity targetIntensity;

  /// Tipos de pregunta permitidos en la etapa.
  final List<QuestionType> allowedTypes;

  /// Permite momentos escasos (recuerdos de voz, promesas, planes...).
  final bool allowsSpecialMoments;

  /// No repite emoción dentro del capítulo mientras el pool lo permita.
  ///
  /// Útil en etapas cortas con pool suficiente (p. ej. el Cierre, 5 emociones
  /// para 5 espacios) para evitar que una misma emoción domine el capítulo y
  /// para cumplir el cierre positivo (Peak-End): cada emoción aparece como
  /// máximo una vez.
  final bool noEmotionRepeat;

  const GameChapter({
    required this.id,
    required this.duration,
    required this.goal,
    required this.approximateQuestionCount,
    required this.emotions,
    required this.minIntensity,
    required this.maxIntensity,
    required this.targetIntensity,
    required this.allowedTypes,
    this.allowsSpecialMoments = false,
    this.noEmotionRepeat = false,
  });

  /// Configuración por defecto de cada etapa según el viaje emocional
  /// descrito en el documento Core GamePlay (§ "¿Cómo se construye una
  /// partida?"). Valores provisionales a afinar.
  /// Copia del capítulo sin los tipos de pregunta excluidos.
  ///
  /// Es el mecanismo del modo online para no jugar formatos que todavía no
  /// están sincronizados a dos dispositivos (comparaciones): se filtra
  /// `allowedTypes` antes de construir la partida y la escalera del selector
  /// nunca ofrecerá esos tipos. Si el filtro dejara la lista vacía se conserva
  /// la original para no romper la partida.
  GameChapter excluding(Set<QuestionType> types) {
    if (types.isEmpty) return this;
    final filtered = allowedTypes.where((t) => !types.contains(t)).toList();
    if (filtered.isEmpty) return this;
    return GameChapter(
      id: id,
      duration: duration,
      goal: goal,
      approximateQuestionCount: approximateQuestionCount,
      emotions: emotions,
      minIntensity: minIntensity,
      maxIntensity: maxIntensity,
      targetIntensity: targetIntensity,
      allowedTypes: filtered,
      allowsSpecialMoments: allowsSpecialMoments,
      noEmotionRepeat: noEmotionRepeat,
    );
  }

  /// Copia de la etapa con una cantidad de espacios ajustada (partidas cortas).
  GameChapter withCount(int count) => GameChapter(
    id: id,
    duration: duration,
    goal: goal,
    approximateQuestionCount: count,
    emotions: emotions,
    minIntensity: minIntensity,
    maxIntensity: maxIntensity,
    targetIntensity: targetIntensity,
    allowedTypes: allowedTypes,
    allowsSpecialMoments: allowsSpecialMoments,
    noEmotionRepeat: noEmotionRepeat,
  );

  factory GameChapter.forChapter(Chapter chapter) {
    switch (chapter) {
      case Chapter.bienvenida:
        return const GameChapter(
          id: Chapter.bienvenida,
          duration: Duration(minutes: 3),
          goal: 'Reducir tensión y hacer que ambos sonrían.',
          approximateQuestionCount: 5,
          emotions: [Emotion.diversion, Emotion.descubrimiento],
          minIntensity: Intensity.suave,
          maxIntensity: Intensity.suave,
          targetIntensity: Intensity.suave,
          allowedTypes: [QuestionType.conversacion, QuestionType.reto],
        );
      case Chapter.calentamiento:
        return const GameChapter(
          id: Chapter.calentamiento,
          duration: Duration(minutes: 6),
          goal: 'Que ambos hablen cada vez más: gustos, opiniones e historias.',
          approximateQuestionCount: 6,
          emotions: [
            Emotion.descubrimiento,
            Emotion.diversion,
            Emotion.nostalgia,
            Emotion.conexion,
          ],
          minIntensity: Intensity.suave,
          maxIntensity: Intensity.media,
          targetIntensity: Intensity.media,
          allowedTypes: [QuestionType.conversacion, QuestionType.reto],
        );
      case Chapter.conexion:
        return const GameChapter(
          id: Chapter.conexion,
          duration: Duration(minutes: 12),
          goal: 'Momentos de romance, nostalgia, futuro y pequeños retos.',
          approximateQuestionCount: 8,
          emotions: [
            Emotion.romance,
            Emotion.nostalgia,
            Emotion.futuro,
            Emotion.coqueteo,
            Emotion.celebracion,
            Emotion.diversion,
            Emotion.conexion,
          ],
          minIntensity: Intensity.media,
          maxIntensity: Intensity.alta,
          targetIntensity: Intensity.alta,
          allowedTypes: [
            QuestionType.conversacion,
            QuestionType.reto,
            QuestionType.comodin,
            QuestionType.comparacion,
          ],
        );
      case Chapter.momentoEspecial:
        return const GameChapter(
          id: Chapter.momentoEspecial,
          duration: Duration(minutes: 3),
          goal: 'El momento que la pareja recordará: promesa, plan, voz...',
          approximateQuestionCount: 1,
          emotions: [
            Emotion.recuerdo,
            Emotion.romance,
            Emotion.futuro,
            Emotion.celebracion,
          ],
          minIntensity: Intensity.alta,
          maxIntensity: Intensity.intensa,
          targetIntensity: Intensity.intensa,
          allowedTypes: [QuestionType.voz],
          allowsSpecialMoments: true,
        );
      case Chapter.cierre:
        // El cierre no vuelve a bajar la intensidad al mínimo (evita el corte
        // brusco tras el pico del momento especial): se mantiene en Alta con
        // emociones positivas (Peak-End Rule, "terminar arriba").
        return const GameChapter(
          id: Chapter.cierre,
          duration: Duration(minutes: 2),
          goal: 'Terminar arriba con una emoción positiva (Peak-End Rule).',
          approximateQuestionCount: 5,
          emotions: [
            Emotion.romance,
            Emotion.nostalgia,
            Emotion.celebracion,
            Emotion.futuro,
            Emotion.recuerdo,
          ],
          minIntensity: Intensity.alta,
          maxIntensity: Intensity.alta,
          targetIntensity: Intensity.alta,
          allowedTypes: [
            QuestionType.conversacion,
            QuestionType.reto,
            QuestionType.comparacion,
          ],
          // Cierre corto con pool exacto (5 emociones, 5 espacios): cada
          // emoción aparece como máximo una vez y la partida termina con la
          // variedad del Peak-End sin que nostalgia domine el capítulo.
          noEmotionRepeat: true,
        );
    }
  }
}
