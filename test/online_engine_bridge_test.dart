import 'dart:math';

import 'package:LoveQuiz/features/game_engine/data/engine_match_codec.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/enums/question_type.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_chapter.dart';
import 'package:LoveQuiz/features/game_engine/domain/models/game_round.dart';
import 'package:LoveQuiz/features/game_engine/engine/playable_match_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Orden esperado del recorrido completo (25 rondas).
const List<Chapter> _expectedOrder = [
  Chapter.bienvenida,
  Chapter.bienvenida,
  Chapter.bienvenida,
  Chapter.bienvenida,
  Chapter.bienvenida,
  Chapter.calentamiento,
  Chapter.calentamiento,
  Chapter.calentamiento,
  Chapter.calentamiento,
  Chapter.calentamiento,
  Chapter.calentamiento,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.conexion,
  Chapter.momentoEspecial,
  Chapter.cierre,
  Chapter.cierre,
  Chapter.cierre,
  Chapter.cierre,
  Chapter.cierre,
];

void main() {
  group('GameChapter.excluding (modo online sin comparaciones)', () {
    test('Conexión permite comparaciones por diseño', () {
      final conexion = GameChapter.forChapter(Chapter.conexion);
      expect(conexion.allowedTypes, contains(QuestionType.comparacion));
    });

    test('excluding quita comparaciones y conserva el resto', () {
      final conexion = GameChapter.forChapter(Chapter.conexion);
      final cierre = GameChapter.forChapter(Chapter.cierre);

      final sinConexion = conexion.excluding({QuestionType.comparacion});
      final sinCierre = cierre.excluding({QuestionType.comparacion});

      expect(sinConexion.allowedTypes, isNot(contains(QuestionType.comparacion)));
      expect(sinConexion.allowedTypes, contains(QuestionType.conversacion));
      expect(sinConexion.allowedTypes, contains(QuestionType.reto));
      expect(sinConexion.allowedTypes, contains(QuestionType.comodin));

      expect(sinCierre.allowedTypes, isNot(contains(QuestionType.comparacion)));
      expect(sinCierre.allowedTypes, contains(QuestionType.conversacion));
      expect(sinCierre.allowedTypes, contains(QuestionType.reto));

      // El resto de la plantilla del capítulo se conserva intacta.
      expect(sinConexion.emotions, conexion.emotions);
      expect(sinConexion.approximateQuestionCount, conexion.approximateQuestionCount);
    });

    test('excluding con lista vacía devuelve el mismo capítulo', () {
      final conexion = GameChapter.forChapter(Chapter.conexion);
      expect(identical(conexion.excluding(const {}), conexion), isTrue);
    });

    test('Momento especial (voz) no se ve afectado', () {
      final especial = GameChapter.forChapter(Chapter.momentoEspecial);
      final sinEspecial = especial.excluding({QuestionType.comparacion});
      expect(sinEspecial.allowedTypes, [QuestionType.voz]);
    });
  });

  group('Partida online del motor con comparaciones (Fase 3)', () {
    test('recorre las 25 rondas conservando comparaciones', () async {
      final rounds = await buildEngineMatch(random: Random(4));

      expect(rounds, hasLength(25));
      expect(rounds.map((r) => r.chapter).toList(), _expectedOrder);

      // Las comparaciones vuelven a jugarse online (Fase 3): el espacio de
      // conexión puede ofrecerlas y, con este seed, al menos una ronda elige
      // una pregunta de comparación que se sincronizará entre dispositivos.
      final comparisonRounds = rounds.where(
        (r) => r.question?.type == QuestionType.comparacion,
      );
      expect(comparisonRounds, isNotEmpty);

      // El momento especial se conserva (voz garantizada).
      final specials = rounds.where((r) => r.isSpecial).toList();
      expect(specials, hasLength(1));
      expect(specials.single.question!.type, QuestionType.voz);
    });

    test('el anfitrión guarda y el invitado reconstruye el mismo recorrido',
        () async {
      // Host: construye la partida con comparaciones y la codifica a la sala.
      final rounds = await buildEngineMatch(random: Random(12));
      final sala = <String, dynamic>{
        'engineRounds': encodeEngineMatch(rounds),
        'currentQuestion': 0,
        'turn': 0,
        'status': 'playing',
      };

      // Guest: lee `engineRounds` del snapshot y reconstruye.
      final restored = decodeEngineMatch(sala['engineRounds'] as List);

      expect(restored, hasLength(25));
      expect(
        restored.map((r) => r.toMap()).toList(),
        rounds.map((r) => r.toMap()).toList(),
        reason: 'el recorrido reconstruido debe ser idéntico mapa a mapa',
      );
      expect(
        restored.any((r) => r.question?.type == QuestionType.comparacion),
        isTrue,
        reason: 'las comparaciones deben atravesar el codec sin perderse',
      );
    });
  });

  group('pickNoVoiceFallback en online', () {
    Future<GameRound> specialRound() async {
      final rounds = await buildEngineMatch(random: Random(42));
      return rounds.firstWhere((r) => r.isSpecial);
    }

    test('por defecto nunca devuelve voz', () async {
      final round = await specialRound();
      final fallback = await pickNoVoiceFallback(
        round: round,
        random: Random(1),
      );
      expect(fallback, isNotNull);
      expect(fallback!.type, isNot(QuestionType.voz));
    });

    test('con excludedTypes tampoco devuelve comparación', () async {
      final round = await specialRound();
      final fallback = await pickNoVoiceFallback(
        round: round,
        random: Random(1),
        excludedTypes: const {
          QuestionType.voz,
          QuestionType.comparacion,
        },
      );
      if (fallback != null) {
        expect(fallback.type, isNot(QuestionType.voz));
        expect(fallback.type, isNot(QuestionType.comparacion));
      }
    });

    test('mismo seed → mismo fallback (ambos dispositivos, mismo resultado)',
        () async {
      // Ambos pulsan "responder sin audio" a la vez sobre la MISMA voz. El
      // fallback online se siembra con datos compartidos (sala + índice + id
      // de la voz), así los dos generan la misma pregunta escrita y el
      // engineRounds.$index last-write-wins queda idempotente.
      final round = await specialRound();
      final seed = 'ABCDEF:10:${round.question!.id}'.hashCode;

      final hostFallback = await pickNoVoiceFallback(
        round: round,
        random: Random(seed),
      );
      final guestFallback = await pickNoVoiceFallback(
        round: round,
        random: Random(seed),
      );

      expect(hostFallback, isNotNull);
      expect(guestFallback, isNotNull);
      expect(hostFallback!.id, guestFallback!.id);
    });

    test('excluye preguntas ya usadas en la partida (no repite)', () async {
      final round = await specialRound();

      final first = await pickNoVoiceFallback(
        round: round,
        random: Random(1),
      );
      expect(first, isNotNull);

      // Con el mismo seed, pero marcando la pregunta elegida como usada, el
      // fallback debe elegir una pregunta DIFERENTE (misma categoría/emoción
      // si hay más candidatos, nunca la que ya salió).
      final second = await pickNoVoiceFallback(
        round: round,
        usedQuestionIds: {first!.id},
        random: Random(1),
      );
      expect(second, isNotNull);
      expect(second!.id, isNot(first.id));
    });
  });
}
