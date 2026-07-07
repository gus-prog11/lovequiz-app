import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/questions.dart';
import '../models/category.dart';
import '../models/emotional_model.dart';
import '../services/firestore_service.dart';
import '../services/emotional_service.dart';
import '../services/achievement_service.dart';
import '../services/presence_service.dart';

class GamePlayScreen extends StatefulWidget {
  final String mode;
  final String p1;
  final String p2;
  final List<String> categories;
  final int timerSeconds;
  final String? roomCode;
  final String? playerName;
  final bool isHost;
  final int totalQuestions;

  const GamePlayScreen({
    super.key,
    required this.mode,
    required this.p1,
    required this.p2,
    required this.categories,
    required this.timerSeconds,
    this.roomCode,
    this.playerName,
    this.isHost = false,
    required this.totalQuestions,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  /// Database instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Variables de control del juego
  List<Question> _questions = []; // Lista de preguntas cargadas
  int _currentIndex = 0; // Índice de la pregunta actual
  int _turn = 0; // Turno actual (0 = jugador 1, 1 = jugador 2)
  bool _gameOver = false; // Indica si el juego ha terminado
  Timer? _timer; // Temporizador para limitar tiempo por pregunta
  int _remainingTime = 0; // Tiempo restante en segundos

  /// Variables de animación
  late AnimationController
  _cardController; // Controla animaciones de las tarjetas
  late Animation<double> _cardAnimation; // Animación de la tarjeta de preguntas

  final TextEditingController _answerCtrl = TextEditingController();
  bool _answerSaved = false;

  /// Variables de sincronización
  bool _initialized = false; // Indica si el juego ha sido inicializado
  StreamSubscription? _roomSubscription; // Escucha cambios en partidas online

  /// Variables de presencia
  bool _otherPlayerOnline = true; // Indica si el otro jugador está en línea
  bool _gamePausedDueToDisconnection =
      false; // Indica si el juego está pausado por desconexión
  StreamSubscription?
  _presenceSubscription; // Escucha cambios de presencia del otro jugador

  /// Inicializa el estado del widget y configura las animaciones
  /// Si el modo es online, inicializa el juego online; si no, carga las preguntas localmente
  @override
  void initState() {
    super.initState();
    _remainingTime = widget.timerSeconds;

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );

    if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineGame();
    } else {
      _questions = getRandomQuestions(widget.categories, widget.totalQuestions);
      _initialized = true;
      _cardController.forward();
      _startTimer();
    }
  }

  /// Inicializa una partida en línea
  /// El anfitrión genera las preguntas y las guarda en Firestore
  /// El cliente espera a recibir las preguntas del anfitrión
  /// Escucha cambios en Firestore para sincronizar el estado del juego
  /// También inicializa el monitoreo de presencia
  Future<void> _initOnlineGame() async {
    final code = widget.roomCode!;

    // Inicializar presencia del usuario actual
    await PresenceService.setPresenceOnline(code);

    if (widget.isHost) {
      final roomDoc = await _db.collection('rooms').doc(code).get();
      final roomData = roomDoc.data();
      final remoteQuestions = roomData?['questions'];

      if (remoteQuestions is List && remoteQuestions.isNotEmpty) {
        _questions = remoteQuestions
            .map(
              (q) => Question(
                text: q['text']?.toString() ?? '',
                category: q['category']?.toString() ?? '',
              ),
            )
            .toList();
      } else {
        _questions = getRandomQuestions(
          widget.categories,
          widget.totalQuestions,
        );
        final qList = _questions
            .map((q) => {'text': q.text, 'category': q.category})
            .toList();
        await FirestoreService.saveQuestions(code, qList);
      }

      if (!mounted) return;
      setState(() => _initialized = true);
      _cardController.forward();
      _startTimer();
    }

    // Monitorear presencia del otro jugador
    _monitorOtherPlayerPresence(code);

    _roomSubscription = FirestoreService.roomStream(code).listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final qData = data['questions'];
      if (!widget.isHost &&
          qData != null &&
          qData is List &&
          qData.isNotEmpty) {
        final newQuestions = qData
            .map(
              (q) => Question(
                text: q['text'] as String,
                category: q['category'] as String,
              ),
            )
            .toList();
        if (!_initialized) {
          setState(() {
            _questions = newQuestions;
            _initialized = true;
          });
          _cardController.forward();
          _startTimer();
        }
      }

      final remoteIndex = data['currentQuestion'] as int? ?? 0;
      final remoteTurn = data['turn'] as int? ?? 0;
      final status = data['status'] as String? ?? '';
      final isFinished = status == 'finished';

      if (isFinished && !_gameOver) {
        _stopTimer();
        setState(() => _gameOver = true);
        return;
      }

      // AMBOS jugadores escuchan cambios de Firestore y actualizan su pantalla
      // Esto asegura que cuando uno presiona siguiente, el otro también ve el cambio
      if (_gameOver && status == 'playing') {
        _cardController.reset();
        setState(() {
          _currentIndex = remoteIndex;
          _turn = remoteTurn;
          _gameOver = false;
        });
        _cardController.forward();
        _startTimer();
        return;
      }

      // Actualizar cuando el otro jugador presiona siguiente
      if ((remoteIndex != _currentIndex || remoteTurn != _turn) && !_gameOver) {
        _cardController.reset();
        setState(() {
          _currentIndex = remoteIndex;
          _turn = remoteTurn;
        });
        _cardController.forward();
        _startTimer();
      }
    });
  }

  /// Limpia los recursos cuando el widget se destruye
  /// Cancela el temporizador, la suscripción a Firestore y detiene las animaciones
  /// También limpia la presencia si es un juego online
  @override
  void dispose() {
    _timer?.cancel();
    _roomSubscription?.cancel();
    _presenceSubscription?.cancel();
    _cardController.dispose();
    _answerCtrl.dispose();

    // Marcar como desconectado si es un juego online
    if (widget.mode == 'online' && widget.roomCode != null) {
      PresenceService.setPresenceOffline(widget.roomCode!);
    }

    PresenceService.dispose();
    super.dispose();
  }

  /// Monitorea la presencia del otro jugador
  /// Si se desconecta, pausa el juego y muestra una notificación
  /// Si se vuelve a conectar, reanuda el juego
  void _monitorOtherPlayerPresence(String roomCode) {
    // Obtener el ID del otro jugador basado en el rol
    // En un juego online, necesitamos identificar el ID del otro usuario
    // Esta es una aproximación simple que asume que tenemos el nombre del otro jugador

    _presenceSubscription = _db
        .collection('rooms')
        .doc(roomCode)
        .collection('presence')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          // Obtener el usuario actual
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return;

          // Encontrar el otro usuario en presencia
          var otherPlayerOnline = false;
          for (var doc in snapshot.docs) {
            if (doc.id != currentUserId) {
              final data = doc.data();
              final lastSeen = data['lastSeen'] as Timestamp?;
              if (lastSeen != null) {
                final now = DateTime.now();
                final lastSeenTime = lastSeen.toDate();
                final diffSeconds = now.difference(lastSeenTime).inSeconds;
                otherPlayerOnline = diffSeconds < 30; // Timeout de 30 segundos
              }
            }
          }

          // Si el estado cambió, actualizar y notificar
          if (otherPlayerOnline != _otherPlayerOnline) {
            setState(() => _otherPlayerOnline = otherPlayerOnline);

            if (!otherPlayerOnline &&
                !_gamePausedDueToDisconnection &&
                !_gameOver) {
              // El otro jugador se desconectó
              _stopTimer();
              setState(() => _gamePausedDueToDisconnection = true);

              _showDisconnectionDialog(widget.p2);
            } else if (otherPlayerOnline &&
                _gamePausedDueToDisconnection &&
                !_gameOver) {
              // El otro jugador se reconectó
              setState(() => _gamePausedDueToDisconnection = false);

              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              _startTimer();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡${widget.p2} se ha reconectado!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        });
  }

  /// Muestra un diálogo cuando el otro jugador se desconecta
  void _showDisconnectionDialog(String playerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.wifi_off, color: Colors.red, size: 32),
          title: Text('$playerName se desconectó'),
          content: const Text(
            'El otro jugador ha perdido la conexión. El juego se ha pausado. Por favor espera a que se reconecte.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitGame();
              },
              child: const Text('Salir del juego'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAsFavorite() async {
    if (_currentQuestion == null || _answerCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = await EmotionalService.generateFavoriteAnswerId();
    await EmotionalService.saveFavoriteAnswer(
      FavoriteAnswer(
        id: id,
        userId: user.uid,
        question: _currentQuestion!.text,
        answer: _answerCtrl.text.trim(),
        category: _currentQuestion!.category,
        partnerName: _turn == 0 ? widget.p2 : widget.p1,
        createdAt: Timestamp.now(),
      ),
    );
    await AchievementService.updateConfessionStats();
    setState(() => _answerSaved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Respuesta guardada como favorita!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Inicia un temporizador que reduce el tiempo cada segundo
  /// Cuando el tiempo llega a 0, avanza automáticamente a la siguiente pregunta
  void _startTimer() {
    if (widget.timerSeconds <= 0) return;
    _remainingTime = widget.timerSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
        _nextQuestion();
      }
    });
  }

  /// Detiene el temporizador actual
  void _stopTimer() {
    _timer?.cancel();
  }

  /// Avanza a la siguiente pregunta
  /// Si es la última pregunta, finaliza el juego
  /// Alterna el turno entre los dos jugadores y anima la transición
  /// Sincroniza el estado si el juego es en línea
  void _nextQuestion() {
    _stopTimer();
    if (_currentIndex >= _questions.length - 1) {
      _finishGame();
      return;
    }
    _cardController.reset();
    setState(() {
      _currentIndex++;
      _turn = _turn == 0 ? 1 : 0;
      _answerCtrl.clear();
      _answerSaved = false;
    });
    _cardController.forward();
    _startTimer();
    _syncGameState();
  }

  /// Sincroniza el estado actual del juego con Firestore
  /// Actualiza el índice de pregunta y el turno para que el otro jugador lo vea
  Future<void> _syncGameState() async {
    if (widget.mode == 'online' && widget.roomCode != null) {
      await FirestoreService.nextQuestion(
        widget.roomCode!,
        _currentIndex,
        _turn,
      );
    }
  }

  /// Finaliza el juego
  /// Detiene el temporizador y actualiza el estado en Firestore si es online
  Future<void> _finishGame() async {
    _stopTimer();

    await FirestoreService.saveGameHistory(
      player1: widget.p1,
      player2: widget.p2,
      mode: widget.mode,
      categories: widget.categories,
      questionsAnswered: _currentIndex + 1,
    );

    await AchievementService.updateGameStats(
      _currentIndex + 1,
      (widget.timerSeconds > 0
          ? (_currentIndex + 1) * widget.timerSeconds ~/ 60
          : 1),
    );

    setState(() => _gameOver = true);

    if (widget.mode == 'online' && widget.roomCode != null) {
      await FirestoreService.finishGame(widget.roomCode!);
    }
  }

  /// Reinicia el juego con nuevas preguntas
  /// Carga nuevas preguntas y reinicia todos los contadores
  /// Si es online y es el anfitrión, actualiza Firestore
  void _restartGame() {
    _cardController.reset();
    if (widget.mode == 'online' && widget.roomCode != null && widget.isHost) {
      final qList = _questions
          .map((q) => {'text': q.text, 'category': q.category})
          .toList();
      FirestoreService.saveQuestions(widget.roomCode!, qList);
      FirestoreService.restartGame(widget.roomCode!);
    }
    setState(() {
      if (widget.mode != 'online') {
        _questions = getRandomQuestions(
          widget.categories,
          widget.totalQuestions,
        );
      }
      _currentIndex = 0;
      _turn = 0;
      _gameOver = false;
    });
    _cardController.forward();
    _startTimer();
  }

  /// Salir del juego y volver a la pantalla principal
  /// Detiene el temporizador y finaliza la partida si es online
  void _exitGame() {
    _stopTimer();
    if (widget.mode == 'online' && widget.roomCode != null) {
      FirestoreService.finishGame(widget.roomCode!);
    }
    context.go('/');
  }

  /// Getters para obtener información del estado actual del juego
  /// _isMyTurn: Verifica si es mi turno (en online compara con el rol del usuario)
  bool get _isMyTurn =>
      widget.mode != 'online' ||
      (_turn == 0 && widget.isHost) ||
      (_turn == 1 && !widget.isHost);

  /// _canAdvance: Determina si se puede avanzar a la siguiente pregunta
  bool get _canAdvance =>
      (widget.mode != 'online' || _isMyTurn) && !_gamePausedDueToDisconnection;

  /// _currentPlayer: Obtiene el nombre del jugador en el turno actual
  String get _currentPlayer => _turn == 0 ? widget.p1 : widget.p2;

  /// _currentQuestion: Obtiene la pregunta actual de la lista
  Question? get _currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
      ? _questions[_currentIndex]
      : null;

  /// Obtiene el color de fondo basado en la categoría de la pregunta
  /// Cada categoría tiene un color único para mejor identificación visual
  Color _getCategoryColor(String categoryId) {
    final cat = getCategoryById(categoryId);
    if (cat == null) return Colors.grey.shade100;
    switch (cat.color) {
      case 'pink':
        return Colors.pink.shade100;
      case 'red':
        return Colors.red.shade100;
      case 'orange':
        return Colors.orange.shade100;
      case 'yellow':
        return Colors.yellow.shade100;
      case 'purple':
        return Colors.purple.shade100;
      case 'cyan':
        return Colors.cyan.shade100;
      case 'green':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  /// Construye la interfaz principal del juego
  /// Si el juego terminó, muestra la pantalla de fin
  /// Si no está inicializado, muestra un indicador de carga
  /// Si no, muestra la pregunta actual con controles de navegación
  @override
  Widget build(BuildContext context) {
    if (_gameOver) {
      return _buildGameOver();
    }
    if (!_initialized || _currentQuestion == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                widget.mode == 'online' && !widget.isHost
                    ? "Cargando juego..."
                    : "Preparando preguntas...",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _exitGame,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text("Salir", style: TextStyle(fontSize: 12)),
                  ),
                  if (widget.timerSeconds > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingTime <= 5
                            ? Colors.red.shade100
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: _remainingTime <= 5
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_remainingTime}s",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _remainingTime <= 5
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.mode == 'online')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _otherPlayerOnline
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _otherPlayerOnline ? Icons.wifi : Icons.wifi_off,
                            size: 14,
                            color: _otherPlayerOnline
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _otherPlayerOnline ? "Online" : "Desconectado",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _otherPlayerOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      "Local",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              FadeTransition(
                opacity: _cardAnimation,
                child: Column(
                  children: [
                    Text(
                      "Turno de",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPlayer,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ScaleTransition(
                  scale: _cardAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_currentQuestion!.category),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getCategoryById(
                                  _currentQuestion!.category,
                                )?.label ??
                                _currentQuestion!.category,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _currentQuestion!.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _answerCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Escribe su respuesta...',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon:
                                _answerCtrl.text.isNotEmpty && !_answerSaved
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.pink,
                                    ),
                                    tooltip: 'Guardar como favorita',
                                    onPressed: _saveAsFavorite,
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Pregunta ${_currentIndex + 1} de ${_questions.length}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _canAdvance ? _nextQuestion : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _gamePausedDueToDisconnection
                        ? "Esperando reconexión..."
                        : widget.mode == 'online' && !_isMyTurn
                        ? "Esperando a tu pareja..."
                        : "Siguiente",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la pantalla de fin del juego
  /// Muestra una animación de celebración, el número de preguntas respondidas
  /// y opciones para jugar de nuevo o volver al inicio
  Widget _buildGameOver() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: (value - 0.5) * 0.2,
                      child: Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.amber.shade400,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Fin del Juego!",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "${widget.p1} y ${widget.p2} respondieron ${_currentIndex + 1} preguntas juntos",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _restartGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      "Jugar de Nuevo",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _exitGame,
                    icon: const Icon(Icons.favorite),
                    label: const Text(
                      "Volver al Inicio",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
