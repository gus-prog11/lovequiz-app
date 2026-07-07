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
  static Future<void> setPresenceOffline(String roomCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _presenceTimer?.cancel();
    await _updatePresence(roomCode, userId, false);
  }

  /// Actualiza el timestamp de presencia del usuario
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
      await presenceRef.set({
        'userId': userId,
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating presence: $e');
    }
  }

  /// Monitorea la presencia de un usuario específico en la sala
  /// Retorna un stream que emite cambios de presencia
  static Stream<bool> monitorUserPresence(String roomCode, String userId) {
    return _db
        .collection('rooms')
        .doc(roomCode)
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;

          final data = snapshot.data();
          if (data == null) return false;

          final lastSeen = data['lastSeen'] as Timestamp?;
          if (lastSeen == null) return false;

          // Verificar si el timestamp es reciente (dentro de _presenceTimeoutSeconds)
          final now = DateTime.now();
          final lastSeenTime = lastSeen.toDate();
          final diffSeconds = now.difference(lastSeenTime).inSeconds;

          return diffSeconds < _presenceTimeoutSeconds;
        });
  }

  /// Obtiene el estado de presencia actual de un usuario
  static Future<bool> isUserOnline(String roomCode, String userId) async {
    try {
      final doc = await _db
          .collection('rooms')
          .doc(roomCode)
          .collection('presence')
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final lastSeen = data['lastSeen'] as Timestamp?;
      if (lastSeen == null) return false;

      final now = DateTime.now();
      final lastSeenTime = lastSeen.toDate();
      final diffSeconds = now.difference(lastSeenTime).inSeconds;

      return diffSeconds < _presenceTimeoutSeconds;
    } catch (e) {
      print('Error checking user online status: $e');
      return false;
    }
  }

  /// Limpia los datos de presencia de una sala
  static Future<void> cleanupPresence(String roomCode) async {
    try {
      final presenceCollection = await _db
          .collection('rooms')
          .doc(roomCode)
          .collection('presence')
          .get();

      for (var doc in presenceCollection.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up presence: $e');
    }
  }

  /// Detiene el monitoreo de presencia del usuario actual
  static void dispose() {
    _presenceTimer?.cancel();
  }
}
