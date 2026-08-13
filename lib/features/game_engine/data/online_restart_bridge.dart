/// Puente puro para reiniciar partidas online con el motor.
library;

import '../domain/models/game_round.dart';
import 'engine_match_codec.dart';

/// Indica si la sala tiene un recorrido del motor persistido.
bool roomHasEngineMatch(Map<String, dynamic> roomData) {
  final engineRounds = roomData['engineRounds'];
  return engineRounds is List && engineRounds.isNotEmpty;
}

/// Campos Firestore para reiniciar una partida online en una sola escritura.
///
/// El anfitrión escribe el nuevo `engineRounds` junto con los contadores
/// reseteados para que el invitado reciba un snapshot coherente y no
/// reconstruya un recorrido distinto.
Map<String, dynamic> buildOnlineRestartUpdate({
  required List<Map<String, dynamic>> engineRounds,
}) {
  return {
    'currentQuestion': 0,
    'turn': 0,
    'status': 'playing',
    'comparisonP1': null,
    'comparisonP2': null,
    'engineRounds': engineRounds,
  };
}

/// Contenido jugable reconstruido desde el snapshot de la sala tras un restart.
class OnlineRestartContent {
  const OnlineRestartContent({this.engineRounds = const []});

  final List<GameRound> engineRounds;

  bool get usesEngine => engineRounds.isNotEmpty;
}

/// Lee el snapshot de sala después de un restart online.
///
/// El recorrido del motor es la única fuente: si la sala aún no lo tiene,
/// devuelve contenido vacío (no hay fallback legacy en V1).
OnlineRestartContent parseOnlineRestartContent(Map<String, dynamic> roomData) {
  if (roomHasEngineMatch(roomData)) {
    return OnlineRestartContent(
      engineRounds: decodeEngineMatch(roomData['engineRounds'] as List),
    );
  }
  return const OnlineRestartContent();
}
