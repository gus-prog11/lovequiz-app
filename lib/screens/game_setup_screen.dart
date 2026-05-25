import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class GameSetupScreen extends StatefulWidget {
  final String mode;
  final String p1;
  final String p2;
  final String? roomCode;
  final String? playerName;
  final bool isHost;

  const GameSetupScreen({
    super.key,
    required this.mode,
    required this.p1,
    required this.p2,
    this.roomCode,
    this.playerName,
    this.isHost = false,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  List<String> _selectedCategories = [];
  bool _timerEnabled = false;
  int _timerSeconds = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'online' && !widget.isHost && widget.roomCode != null) {
      FirestoreService.roomStream(widget.roomCode!).listen((snapshot) {
        if (!mounted) return;
        final data = snapshot.data();
        if (data == null) return;
        final status = data['status'] as String? ?? '';
        if (status == 'playing') {
          final categories = List<String>.from(data['categories'] ?? []);
          final timer = data['timerSeconds'] as int? ?? 0;
          final totalQuestions = data['totalQuestions'] as int? ?? 30;
          _navigateToPlay(categories, timer, totalQuestions);
        }
      });
    }
  }

  void _toggleCategory(String id) {
    if (!widget.isHost && widget.mode == 'online') return;
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  void _selectAll() {
    if (!widget.isHost && widget.mode == 'online') return;
    setState(() {
      if (_selectedCategories.length == categories.length) {
        _selectedCategories = [];
      } else {
        _selectedCategories = categories.map((c) => c.id).toList();
      }
    });
  }

  void _navigateToPlay(List<String> categories, int timerSeconds, int totalQuestions) {
    if (!mounted) return;
    final params = <String, String>{
      'mode': widget.mode,
      'p1': widget.p1,
      'p2': widget.p2,
      'categories': categories.join(','),
      'timer': timerSeconds.toString(),
    };
    if (widget.roomCode != null) params['roomCode'] = widget.roomCode!;
    if (widget.playerName != null) params['name'] = widget.playerName!;
    if (widget.mode == 'online') params['host'] = widget.isHost.toString();
    context.go('/play?${Uri(queryParameters: params).query}');
  }

  Future<void> _startGame() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una categoría")),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final totalQuestions = 30;
      if (widget.mode == 'online' && widget.roomCode != null) {
        await FirestoreService.updateGameConfig(
          widget.roomCode!,
          _selectedCategories,
          _timerEnabled ? _timerSeconds : 0,
          totalQuestions,
        );
      }
      if (!mounted) return;
      _navigateToPlay(
        _selectedCategories,
        _timerEnabled ? _timerSeconds : 0,
        totalQuestions,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar juego: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getCategoryColor(String colorName) {
    switch (colorName) {
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

  Color _getCategoryTextColor(String colorName) {
    switch (colorName) {
      case 'pink':
        return Colors.pink.shade700;
      case 'red':
        return Colors.red.shade700;
      case 'orange':
        return Colors.orange.shade700;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'purple':
        return Colors.purple.shade700;
      case 'cyan':
        return Colors.cyan.shade700;
      case 'green':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/pairing'),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Configurar Juego",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${widget.p1} 💕 ${widget.p2}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Categories
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "🎯 Elige las categorías",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(${_selectedCategories.length} seleccionadas)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSelected = _selectedCategories.contains(
                            cat.id,
                          );
                          return FilterChip(
                            selected: isSelected,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat.emoji),
                                const SizedBox(width: 4),
                                Text(cat.label),
                              ],
                            ),
                            onSelected: (_) => _toggleCategory(cat.id),
                            selectedColor: _getCategoryColor(cat.color),
                            checkmarkColor: _getCategoryTextColor(cat.color),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? _getCategoryTextColor(cat.color)
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _selectAll,
                        child: Text(
                          _selectedCategories.length == categories.length
                              ? "Deseleccionar todas"
                              : "Seleccionar todas",
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Timer
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Temporizador",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _timerEnabled,
                                  onChanged: (value) =>
                                      setState(() => _timerEnabled = value),
                                ),
                              ],
                            ),
                            if (_timerEnabled) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tiempo por pregunta",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    "${_timerSeconds}s",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _timerSeconds.toDouble(),
                                min: 10,
                                max: 120,
                                divisions: 22,
                                onChanged: (value) => setState(
                                  () => _timerSeconds = value.toInt(),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "10s",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                  Text(
                                    "120s",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: (_selectedCategories.isEmpty || _loading ||
                          (widget.mode == 'online' && !widget.isHost))
                      ? null
                      : _startGame,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    widget.mode == 'online' && !widget.isHost
                        ? "Esperando al anfitrión..."
                        : "¡Empezar! 🔥",
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
}
