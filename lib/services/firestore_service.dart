import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/game_engine/data/online_restart_bridge.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Genera un código aleatorio de 6 caracteres para salas.
  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  // Crea una nueva sala de juego y retorna su código.
  static Future<String> createRoom({
    bool isRandom = false,
    String? hostName,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("No hay un usuario autenticado");
    }

    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    final host = hostName ?? userDoc.data()?['alias'] ?? "Jugador";
    final hostUid = firebaseUser.uid;
    var code = _generateRoomCode();
    bool exists = (await _db.collection('rooms').doc(code).get()).exists;
    while (exists) {
      code = _generateRoomCode();
      exists = (await _db.collection('rooms').doc(code).get()).exists;
    }
    await _db.collection('rooms').doc(code).set({
      'hostName': host,
      'hostUid': hostUid,
      'guestName': null,
      'guestUid': null,
      'status': 'waiting',
      'isRandom': isRandom,
      'categories': <String>[],
      'timerSeconds': 0,
      'currentQuestion': 0,
      'turn': 0,
      'totalQuestions': 30,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  // Permite a un jugador unirse a una sala existente.
  //
  // `guestName` opcional: en emparejamiento aleatorio el jugador escribe su
  // nombre en la pantalla, y ese nombre (no el alias de Firestore) debe quedar
  // registrado en la sala. Si no se pasa, se usa el alias como fallback.
  //
  // La validación y la reserva del invitado ocurren en una transacción: dos
  // joins simultáneos (mismo código o emparejamiento aleatorio) ya no pueden
  // pasar los dos la validación. El segundo read ve `guestName` ocupado y la
  // transacción no escribe, así que solo un invitado queda "dentro".
  static Future<bool> joinRoom(String code, {String? guestName}) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("No hay usuario");
    }

    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    final guest = guestName ?? userDoc.data()?['alias'] ?? "Jugador";
    final guestUid = firebaseUser.uid;

    try {
      final claimed = await _db.runTransaction((txn) async {
        final ref = _db.collection('rooms').doc(code);
        final snapshot = await txn.get(ref);
        if (!snapshot.exists) return false;
        final data = snapshot.data()!;
        if (data['guestName'] != null) return false;
        if (data['status'] != 'waiting') return false;
        txn.update(ref, {
          'guestName': guest,
          'guestUid': guestUid,
        });
        return true;
      });
      return claimed;
    } on FirebaseException {
      // Transacción abortada (modificación concurrente o error de red): la
      // sala no se reservó. El flujo lo trata como "no disponible".
      return false;
    }
  }

  // Busca una sala aleatoria disponible para unirse.
  static Future<String?> findRandomRoom() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception("No hay usuario");
    }

    final userDoc = await _db.collection('users').doc(firebaseUser.uid).get();

    final guestName = userDoc.data()?['alias'] ?? "Jugador";
    final snapshot = await _db
        .collection('rooms')
        .where('status', isEqualTo: 'waiting')
        .where('isRandom', isEqualTo: true)
        .where('guestName', isEqualTo: null)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    if (data['hostName'] == guestName) return null;
    return doc.id;
  }

  // Escucha cambios en tiempo real de una sala.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> roomStream(
    String code,
  ) {
    return _db.collection('rooms').doc(code).snapshots();
  }

  // Actualiza las categorías seleccionadas para la partida.
  static Future<void> updateSelectedCategories(
    String code,
    List<String> categories,
  ) async {
    await _db.collection('rooms').doc(code).update({'categories': categories});
  }

  // Actualiza la configuración del temporizador de la sala.
  static Future<void> updateTimerSettings(String code, int timerSeconds) async {
    await _db.collection('rooms').doc(code).update({
      'timerSeconds': timerSeconds,
    });
  }

  // Actualiza la cantidad de preguntas de la partida en la sala.
  static Future<void> updateTotalQuestions(String code, int totalQuestions) async {
    await _db.collection('rooms').doc(code).update({
      'totalQuestions': totalQuestions,
    });
  }

  // Configura todas las opciones de la partida y la inicia.
  static Future<void> updateGameConfig(
    String code,
    List<String> categories,
    int timerSeconds,
    int totalQuestions,
  ) async {
    await _db.collection('rooms').doc(code).update({
      'categories': categories,
      'timerSeconds': timerSeconds,
      'totalQuestions': totalQuestions,
      'currentQuestion': 0,
      'turn': 0,
      'status': 'playing',
    });
  }

  // Guarda el recorrido del motor en la sala (campo `engineRounds`). Es la
  // única fuente de preguntas del modo online: el invitado lo recibe por
  // `roomStream` y lo reconstruye con `decodeEngineMatch`.
  static Future<void> saveEngineMatch(
    String code,
    List<Map<String, dynamic>> rounds,
  ) async {
    await _db.collection('rooms').doc(code).update({'engineRounds': rounds});
  }

  // Publica el reemplazo escrito de una pregunta de voz (fallback "responder
  // sin audio") en la posición actual del recorrido del motor. Ambos
  // dispositivos leen `engineRounds` por `roomStream` y aplican la MISMA
  // pregunta escrita, así nadie se queda grabando audio hacia una pregunta
  // que ya cambió. El índice se escribe con notación de punto (update de un
  // solo elemento del array) para no pisar el resto de la partida.
  static Future<void> applyNoVoiceFallback(
    String code,
    int index,
    Map<String, dynamic> round,
  ) async {
    await _db.collection('rooms').doc(code).update({
      'engineRounds.$index': round,
    });
  }

  // Guarda la elección de un jugador en la pregunta de comparación actual.
  //
  // `comparisonP1` es la del anfitrión (jugador 1) y `comparisonP2` la del
  // invitado (jugador 2). Cada dispositivo escribe solo su propia elección
  // (pasando null en el rol ajeno) y el otro la recibe por `roomStream`.
  static Future<void> saveComparisonChoice(
    String code, {
    String? player1Choice,
    String? player2Choice,
  }) async {
    final fields = <String, dynamic>{
      'comparisonP1': ?player1Choice,
      'comparisonP2': ?player2Choice,
    };
    if (fields.isEmpty) return;
    await _db.collection('rooms').doc(code).update(fields);
  }

  // Avanza a la siguiente pregunta y cambia el turno.
  // También limpia las elecciones de la comparación, las respuestas escritas
  // y las reacciones de la pregunta anterior para que ningún dispositivo
  // reutilice datos viejos en la pregunta siguiente.
  static Future<void> nextQuestion(
    String code,
    int currentQuestion,
    int turn,
  ) async {
    await _db.collection('rooms').doc(code).update({
      'currentQuestion': currentQuestion,
      'turn': turn,
      'comparisonP1': null,
      'comparisonP2': null,
      'answerP1': null,
      'answerP2': null,
      'reactionP1': null,
      'reactionP2': null,
    });
  }

  // Guarda la respuesta escrita de un jugador en la pregunta actual.
  //
  // `answerP1` es la del anfitrión (jugador 1) y `answerP2` la del invitado
  // (jugador 2). Cada dispositivo escribe solo su propia respuesta (pasando
  // null en el rol ajeno) y el otro la recibe por `roomStream` para montar
  // la revelación cuando ambos respondieron.
  static Future<void> saveTextAnswer(
    String code, {
    String? player1Answer,
    String? player2Answer,
  }) async {
    final fields = <String, dynamic>{
      'answerP1': ?player1Answer,
      'answerP2': ?player2Answer,
    };
    if (fields.isEmpty) return;
    await _db.collection('rooms').doc(code).update(fields);
  }

  // Publica una reacción decorativa de un jugador en la sala.
  //
  // La reacción es un mensaje efímero (~3 s) que ve la pareja: cada rol
  // escribe SOLO su propio campo (`reactionP1`/`reactionP2`) con un `seq`
  // creciente para que el receptor detecte cada tap aunque repita el mismo
  // emoji. Escribir el campo del otro rol aquí lo pisaría: si un jugador
  // reacciona justo después de su pareja, su write con null borraría la
  // reacción ajena antes de que el stream del receptor la lea.
  static Future<void> sendReaction(
    String code, {
    Map<String, dynamic>? player1Reaction,
    Map<String, dynamic>? player2Reaction,
  }) async {
    final fields = <String, dynamic>{
      'reactionP1': ?player1Reaction,
      'reactionP2': ?player2Reaction,
    };
    if (fields.isEmpty) return;
    await _db.collection('rooms').doc(code).update(fields);
  }

  // Limpia el campo de reacción PROPIO de un jugador (~3.5 s después de
  // enviar). Solo toca el rol indicado para no borrar una reacción fresca
  // que la pareja acaba de publicar.
  static Future<void> clearReaction(
    String code, {
    required bool player1,
    required bool player2,
  }) async {
    final fields = <String, dynamic>{
      if (player1) 'reactionP1': null,
      if (player2) 'reactionP2': null,
    };
    if (fields.isEmpty) return;
    await _db.collection('rooms').doc(code).update(fields);
  }

  // Cambia el estado de la sala a configuración.
  static Future<void> setupRoom(String code) async {
    try {
      await _db.collection('rooms').doc(code).update({'status': 'setup'});
    } catch (_) {}
  }

  // Finaliza la partida marcando la sala como terminada.
  static Future<void> finishGame(String code) async {
    try {
      await _db.collection('rooms').doc(code).update({'status': 'finished'});
    } catch (_) {}
  }

  // Reinicia la partida desde la primera pregunta.
  //
  // El anfitrión incluye el nuevo `engineRounds` (motor) en la misma escritura
  // para que host e invitado reciban el mismo recorrido.
  static Future<void> restartGame(
    String code,
    List<Map<String, dynamic>> engineRounds,
  ) async {
    await _db
        .collection('rooms')
        .doc(code)
        .update(buildOnlineRestartUpdate(engineRounds: engineRounds));
  }

  // Elimina una sala de Firestore.
  static Future<void> deleteRoom(String code) async {
    await _db.collection('rooms').doc(code).delete();
  }

  // Permite al invitado salir de la sala.
  static Future<void> leaveRoomAsGuest(String code) async {
    try {
      await _db.collection('rooms').doc(code).update({
        'guestName': null,
        'guestUid': null,
      });
    } catch (_) {}
  }

  // Guarda el historial de una partida jugada.
  static Future<void> saveGameHistory({
    required String player1,
    required String player2,
    required String mode,
    required List<String> categories,
    required int questionsAnswered,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    await _db.collection("game_history").add({
      'userId': user.uid,
      'player1': player1,
      'player2': player2,
      'mode': mode,
      'categories': categories,
      'questionsAnswered': questionsAnswered,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtiene el historial de partidas del usuario actual.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserHistory() {
    final user = FirebaseAuth.instance.currentUser;

    return _db
        .collection('game_history')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
