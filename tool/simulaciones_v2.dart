import 'dart:io';
import 'dart:math';

import 'package:LoveQuiz/features/game_engine/data/question_bank_v1.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Genera `docs/simulaciones_v2.md`: 10 partidas completas del motor (semillas
/// 1..10) en formato legible, con la pregunta asignada a cada ronda y la marca
/// de las preguntas reescritas en la FASE 2 (retexto del banco V1).
///
/// Uso: `flutter test tool/simulaciones_v2.dart`

final _rewritten = <String>{
  // A. Calentamiento (thematic).
  'nue-incomodas-calentamiento-nostalgia-8',
  'nue-incomodas-calentamiento-nostalgia-13',
  'nue-incomodas-calentamiento-descubrimiento-11',
  'nue-incomodas-calentamiento-descubrimiento-12',
  'nue-incomodas-calentamiento-descubrimiento-13',
  'nue-incomodas-calentamiento-descubrimiento-14',
  'nue-incomodas-calentamiento-descubrimiento-15',
  'nue-incomodas-calentamiento-descubrimiento-16',
  'nue-extremas-calentamiento-nostalgia-8',
  'nue-extremas-calentamiento-nostalgia-11',
  'nue-extremas-calentamiento-nostalgia-13',
  'nue-extremas-calentamiento-nostalgia-15',
  'nue-extremas-calentamiento-descubrimiento-13',
  'nue-extremas-calentamiento-descubrimiento-16',
  'nue-extremas-calentamiento-descubrimiento-17',
  'nue-extremas-calentamiento-descubrimiento-18',
  // B. Bienvenida extremas (thematic).
  'nue-extremas-bienvenida-descubrimiento-1',
  'nue-extremas-bienvenida-descubrimiento-2',
  'nue-extremas-bienvenida-descubrimiento-4',
  // C. Conversaciones "¿Quién de los dos…?" (thematic).
  'nue-calientes-calentamiento-diversion-2',
  'nue-calientes-calentamiento-diversion-5',
  'nue-calientes-conexion-diversion-2',
  'nue-divertidas-conexion-coqueteo-1',
  // D. Duplicados funcionales intra-bloque (thematic).
  'nue-calientes-conexion-nostalgia-3',
  'nue-calientes-conexion-nostalgia-5',
  'nue-calientes-conexion-futuro-1',
  'nue-calientes-conexion-futuro-5',
  'nue-calientes-conexion-celebracion-2',
  'nue-calientes-conexion-celebracion-3',
  'nue-romanticas-conexion-nostalgia-2',
  'nue-romanticas-conexion-celebracion-2',
  'nue-divertidas-conexion-nostalgia-3',
  'nue-divertidas-conexion-celebracion-3',
  'nue-calientes-conexion-romance-1',
  // G-cierre (thematic).
  'nue-calientes-cierre-nostalgia-3',
  'nue-divertidas-cierre-nostalgia-2',
  // F. Voces legacy.
  'leg-voice-1',
  'leg-voice-2',
  'leg-voice-6',
  'leg-voice-8',
  'leg-voice-10',
  // E. futuro / familia legacy.
  'leg-futuro-3',
  'leg-futuro-4',
  'leg-futuro-8',
  'leg-futuro-10',
  'leg-familia-6',
  'leg-familia-7',
  'leg-familia-12',
  'leg-familia-14',
  // G-cerradas legacy.
  'leg-romanticas-3',
  'leg-romanticas-17',
  'leg-romanticas-20',
  'leg-romanticas-44',
  'leg-romanticas-53',
  'leg-romanticas-56',
};

const _typeLabel = <String, String>{
  'conversacion': 'Conversación',
  'comparacion': 'Comparación',
  'voz': 'Voz',
  'reto': 'Reto',
  'comodin': 'Comodín',
};

String _pad(int n) => n.toString().padLeft(2, '0');

void main() {
  test('simulaciones legibles (10 partidas)', () async {
    final sb = StringBuffer();
    sb.writeln('# Simulaciones del banco V1');
    sb.writeln();
    sb.writeln('> 10 partidas completas del motor (25 espacios) generadas con '
        '`buildEngineMatch` sobre el banco V1 de 1161 preguntas. Cada ronda '
        'muestra la pregunta asignada en orden de juego. Las preguntas '
        'reescritas en la FASE 2 (55 retextos) se marcan con `★`.');
    sb.writeln();

    for (var seed = 1; seed <= 10; seed++) {
      final rounds = await buildEngineMatch(random: Random(seed));
      final types = <String, int>{};
      var rewrittenShown = 0;
      var specialShown = 0;
      for (final r in rounds) {
        final q = r.question!;
        types[q.type.name] = (types[q.type.name] ?? 0) + 1;
        if (_rewritten.contains(q.id)) rewrittenShown++;
        if (q.isSpecial) specialShown++;
      }

      sb.writeln('## Simulación $seed — semilla $seed');
      sb.writeln();
      sb.writeln('**Rondas jugadas:** ${rounds.length} · '
          '**Comparaciones:** ${types['comparacion'] ?? 0} · '
          '**Voces:** ${types['voz'] ?? 0} · '
          '**Retos:** ${types['reto'] ?? 0} · '
          '**Comodines:** ${types['comodin'] ?? 0} · '
          '**Reescritas mostradas:** $rewrittenShown · '
          '**Momento especial (voz):** ${specialShown > 0 ? 'sí' : 'no'}');
      sb.writeln();
      sb.writeln('```');
      for (var i = 0; i < rounds.length; i++) {
        final r = rounds[i];
        final q = r.question!;
        final mark = _rewritten.contains(q.id) ? ' ★' : '';
        sb.writeln(
          'Ronda ${_pad(i + 1)} | ${r.chapter.label} | ${r.emotion.label} | '
          '${r.intensity.label} | ${_typeLabel[q.type.name] ?? q.type.name} | '
          '${q.category.label} | ${q.text}$mark',
        );
      }
      sb.writeln('```');
      sb.writeln();
    }

    sb.writeln('## Apéndice — las 55 reescritas (FASE 2)');
    sb.writeln();
    sb.writeln('Cada pregunta reescrita con su celda actual '
        '(capítulo · emoción · intensidad · tipo · categoría) y el nuevo texto. '
        'Ordenadas como en el plan de FASE 2: A calentamiento, B bienvenida, '
        'C conversaciones, D duplicados funcionales, G-cierre, F voces, '
        'E futuro/familia, G-cerradas.');
    sb.writeln();
    sb.writeln('```');
    final byId = {for (final q in bancoV1Questions) q.id: q};
    for (final id in _rewritten) {
      final q = byId[id];
      if (q == null) {
        sb.writeln('NO ENCONTRADA\t$id');
        continue;
      }
      sb.writeln(
        '${q.id} | ${q.chapter.label} · ${q.emotion.label} · '
        '${q.intensity.label} · ${_typeLabel[q.type.name] ?? q.type.name} · '
        '${q.category.label} | ${q.text}',
      );
    }
    sb.writeln('```');
    sb.writeln();

    File(r'docs\simulaciones_v2.md').writeAsStringSync(sb.toString());
  });
}
