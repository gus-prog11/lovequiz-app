import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Timer? _presenceTimer;
  static const int _presenceTimeoutSeconds =
      30; // Tiempo para considerar al usuario desconectado

  /// Inicializa la presencia del usuario actual en una sala
  /// Actualiza un timestamp cada [_presenceTimeoutSeconds] segundos
  // Marca al usuario como en línea en la sala.
  static Future<void> setPresenceOnline(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Actualizar presencia inmediatamente
    await _updatePresence(roomCode, userId, true);

    // Cancelar timer anterior si existe
    _presenceTimer?.cancel();

    // Actualizar presencia periódicamente
    _presenceTimer = Timer.periodic(
      Duration(seconds: _presenceTimeoutSeconds ~/ 2),
      (_) => _updatePresence(roomCode, userId, true),
    );
  }

  /// Marca al usuario como desconectado
  // Marca al usuario como desconectado en la sala.
  static Future<void> setPresenceOffline(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _presenceTimer?.cancel();
    await _updatePresence(roomCode, userId, false);
  }

  /// Actualiza el timestamp de presencia del usuario
  // Actualiza la presencia en Firestore.
  static Future<void> _updatePresence(
    String roomCode,
    String userId,
    bool isOnline,
  ) async {
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
    } catch (e) {
      print('Error updating presence: $e');
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

  /// Detiene el monitoreo de presencia del usuario actual
  // Detiene el timer de presencia del usuario.
  static void dispose() {
    _presenceTimer?.cancel();
  }
}
