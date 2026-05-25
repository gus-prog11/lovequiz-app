import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/questions.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class GamePlayScreen extends StatefulWidget {
  final String mode;
  final String p1;
  final String p2;
  final List<String> categories;
  final int timerSeconds;
  final String? roomCode;
  final String? playerName;
  final bool isHost;

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
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _turn = 0;
  bool _gameOver = false;
  Timer? _timer;
  int _remainingTime = 0;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  bool _initialized = false;
  StreamSubscription? _roomSubscription;

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
      _questions = getRandomQuestions(widget.categories, 30);
      _initialized = true;
      _cardController.forward();
      _startTimer();
    }
  }

  Future<void> _initOnlineGame() async {
    final code = widget.roomCode!;

    if (widget.isHost) {
      _questions = getRandomQuestions(widget.categories, 30);
      final qList = _questions
          .map((q) => {'text': q.text, 'category': q.category})
          .toList();
      await FirestoreService.saveQuestions(code, qList);
      if (!mounted) return;
      setState(() => _initialized = true);
      _cardController.forward();
      _startTimer();
    }

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

      if (!widget.isHost) {
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

        if ((remoteIndex != _currentIndex || remoteTurn != _turn) &&
            !_gameOver) {
          _cardController.reset();
          setState(() {
            _currentIndex = remoteIndex;
            _turn = remoteTurn;
          });
          _cardController.forward();
          _startTimer();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roomSubscription?.cancel();
    _cardController.dispose();
    super.dispose();
  }

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

  void _stopTimer() {
    _timer?.cancel();
  }

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
    });
    _cardController.forward();
    _startTimer();
    _syncGameState();
  }

  Future<void> _syncGameState() async {
    if (widget.mode == 'online' && widget.roomCode != null) {
      await FirestoreService.nextQuestion(
        widget.roomCode!,
        _currentIndex,
        _turn,
      );
    }
  }

  Future<void> _finishGame() async {
    _stopTimer();
    setState(() => _gameOver = true);
    if (widget.mode == 'online' && widget.roomCode != null) {
      await FirestoreService.finishGame(widget.roomCode!);
    }
  }

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
        _questions = getRandomQuestions(widget.categories, 30);
      }
      _currentIndex = 0;
      _turn = 0;
      _gameOver = false;
    });
    _cardController.forward();
    _startTimer();
  }

  void _exitGame() {
    _stopTimer();
    if (widget.mode == 'online' && widget.roomCode != null) {
      FirestoreService.finishGame(widget.roomCode!);
    }
    context.go('/');
  }

  bool get _isMyTurn =>
      widget.mode != 'online' ||
      (_turn == 0 && widget.isHost) ||
      (_turn == 1 && !widget.isHost);
  bool get _canAdvance => widget.mode != 'online' || _isMyTurn;
  String get _currentPlayer => _turn == 0 ? widget.p1 : widget.p2;
  Question? get _currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
      ? _questions[_currentIndex]
      : null;

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
                  Text(
                    widget.mode == 'local' ? "Local" : "Online",
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
                          ),
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
                    widget.mode == 'online' && !_isMyTurn
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
