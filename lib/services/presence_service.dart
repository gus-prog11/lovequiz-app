import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PresenceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Timer? _presenceTimer;
  static const int _presenceTimeoutSeconds =
      30; // Tiempo para considerar al usuario desconectado

  /// Sala a la que pertenece el heartbeat actual. El callback del timer
  /// verifica este valor antes de escribir: si el usuario ya cambió de sala
  /// (o salió), un tick viejo en vuelo no debe resucitar la presencia de la
  /// sala anterior.
  static String? _activeRoomCode;

  /// Incrementa con cada `setPresenceOnline`/`setPresenceOffline`. El callback
  /// periódico captura su valor al programarse y se descarta si cambió, para
  /// que un timer cancelado tarde NO siga escribiendo presencia.
  static int _presenceGeneration = 0;

  /// Inicializa la presencia del usuario actual en una sala
  /// Actualiza un timestamp cada [_presenceTimeoutSeconds] segundos
  // Marca al usuario como en línea en la sala.
  static Future<void> setPresenceOnline(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Cancelar el timer ANTERIOR y anular cualquier tick en vuelto ANTES de
    // escribir: si se marcó offline otra sala o se cambió de sala, el timer
    // viejo no debe sobreescribir `_presenceTimer` ni escribir en la sala
    // vieja (R3).
    _presenceTimer?.cancel();
    _activeRoomCode = roomCode;
    final generation = ++_presenceGeneration;

    // Actualizar presencia inmediatamente. El error de la PRIMERA escritura
    // se propaga (rethrow) para que `_initOnlineGame` lo capture y muestre el
    // error con "Reintentar" en vez de seguir como si la presencia estuviera
    // activa (R9-F1).
    await _updatePresence(roomCode, userId, true, propagate: true);
    if (generation != _presenceGeneration) return;

    // Actualizar presencia periódicamente.
    _presenceTimer = Timer.periodic(
      Duration(seconds: _presenceTimeoutSeconds ~/ 2),
      (_) {
        // Un tick programado para una sala que ya no es la activa se ignora
        // (la cancelación pudo llegar tarde porque el callback estaba en
        // vuelo).
        if (_activeRoomCode != roomCode) return;
        if (generation != _presenceGeneration) return;
        // El heartbeat falla en silencio pero con log: la pareja degrada por
        // frescura de lastSeen; no debe tumbar la app ni propagar un error
        // async en un Timer.
        _updatePresence(roomCode, userId, true, propagate: false);
      },
    );
  }

  /// Marca al usuario como desconectado
  // Marca al usuario como desconectado en la sala.
  static Future<void> setPresenceOffline(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _presenceTimer?.cancel();
    ++_presenceGeneration;
    if (_activeRoomCode == roomCode) _activeRoomCode = null;

    // Se propaga el error: si falla, la pareja nos vería online hasta que
    // lastSeen envejezca; el llamador decide cómo avisar.
    await _updatePresence(roomCode, userId, false, propagate: true);
  }

  /// Actualiza el timestamp de presencia del usuario
  // Actualiza la presencia en Firestore.
  static Future<void> _updatePresence(
    String roomCode,
    String userId,
    bool isOnline, {
    bool propagate = false,
  }) async {
    try {
      final presenceRef = _db
          .collection('rooms')
          .doc(roomCode)
          .collection('presence')
          .doc(userId);
      if (isOnline) {
        await presenceRef.set({
          'userId': userId,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } else {
        // Al salir NO se refresca lastSeen: si se tocara, la pareja (que usa
        // lastSeen como señal de frescura) nos seguiría viendo online hasta
        // 30s después de que nos fuimos. isOnline:false basta para que el
        // monitor del otro jugador corte de inmediato.
        await presenceRef.set({
          'userId': userId,
          'isOnline': false,
        });
      }
    } catch (e, st) {
      debugPrint('[Presence] error updating presence: $e\n$st');
      if (propagate) rethrow;
    }
  }

  /// Monitorea si el OTRO jugador de la sala está en línea (señal reciente).
  /// Descarta al usuario actual y considera al otro con un lastSeen dentro de
  /// [_presenceTimeoutSeconds].
  ///
  /// Un `isOnline: false` explícito vale como desconexión inmediata, sin
  /// esperar a que lastSeen envejezca (antes, salir de la sala refrescaba el
  /// timestamp y la pareja te veía online hasta 30s después).
  // Emite si el otro jugador de la sala está en línea.
  static Stream<bool> monitorOtherPlayerOnline(String roomCode) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('presence')
        .snapshots()
        .map((snapshot) {
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return false;

          var online = false;
          for (final doc in snapshot.docs) {
            if (doc.id == currentUserId) continue;

            final data = doc.data();
            // Desconexión explícita (documentos viejos sin el campo se tratan
            // solo por frescura de lastSeen, para no romper salas antiguas).
            if (data['isOnline'] == false) continue;

            final lastSeen = data['lastSeen'] as Timestamp?;
            if (lastSeen == null) continue;

            final now = DateTime.now();
            final lastSeenTime = lastSeen.toDate();
            final diffSeconds = now.difference(lastSeenTime).inSeconds;
            if (diffSeconds < _presenceTimeoutSeconds) {
              online = true;
            }
          }
          return online;
        });
  }

  /// Detiene el monitoreo de presencia del usuario actual.
  ///
  /// NOTA: intencionalmente NO cancela `_presenceTimer` por su cuenta. El
  /// heartbeat se cancela en `setPresenceOffline` (que es quien lo reemplaza
  /// por un estado offline). Si aquí se cancelara el timer global, el dispose
  /// de una pantalla vieja (p. ej. al salir y entrar rápido a una partida
  /// nueva) mataría el heartbeat de la partida recién creada y la pareja
  /// vería al jugador offline sin motivo (R9-F2).
  static void dispose() {
    // No-op intencional; ver doc de clase.
  }
}
