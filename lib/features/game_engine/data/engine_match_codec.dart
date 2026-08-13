/// Puente de serialización del recorrido del motor hacia la sala online
/// (Fase 1). El host construye la partida con `buildEngineMatch` y la guarda
/// como una lista de mapas en el campo `engineRounds` de la sala (vía
/// `FirestoreService.saveEngineMatch`); el invitado la lee desde el
/// `roomStream` existente y la reconstruye con [decodeEngineMatch]. El flujo
/// legacy (`questions`, `currentQuestion`, `turn`) no se toca: este campo es
/// adicional para que la Fase 2 pueda consumirlo sin cambiar lo que ya
/// funciona.
library;

import '../domain/models/game_round.dart';

/// Codifica el recorrido del motor a la forma que se guarda en la sala.
List<Map<String, dynamic>> encodeEngineMatch(List<GameRound> rounds) =>
    rounds.map((round) => round.toMap()).toList(growable: false);

/// Decodifica el recorrido guardado en la sala de vuelta a [GameRound].
List<GameRound> decodeEngineMatch(List<dynamic> raw) => raw
    .map((entry) => GameRound.fromMap(Map<String, dynamic>.from(entry as Map)))
    .toList(growable: false);
