import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/questions.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import '../services/premium_service.dart';
import '../utils/game_config.dart';

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
  final List<String> _selectedCategories = [];
  bool _timerEnabled = false;
  int _timerSeconds = 30;
  bool _loading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremium();
    if (widget.mode == 'online' && !widget.isHost && widget.roomCode != null) {
      FirestoreService.roomStream(widget.roomCode!).listen((snapshot) {
        if (!mounted) return;
        final data = snapshot.data();
        if (data == null) return;
        final status = data['status'] as String? ?? '';
        if (status == 'playing') {
          final categories = normalizeCategories(data['categories']);
          final timer = normalizeTimerSeconds(data['timerSeconds']);
          final totalQuestions = normalizeTotalQuestions(
            data['totalQuestions'],
            fallback: 30,
          );
          if (categories.isNotEmpty) {
            _navigateToPlay(categories, timer, totalQuestions);
          }
        }
      });
    }
  }

  Future<void> _loadPremium() async {
    final premium = await PremiumService.getPremiumStatus();
    if (mounted) setState(() => _isPremium = premium.isPremium);
  }

  void _toggleCategory(String id) {
    if (!widget.isHost && widget.mode == 'online') return;
    final cat = getCategoryById(id);
    if (cat != null && cat.isPremium && !_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Categoría Premium. ¡Obtén Premium para desbloquearla!',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  void _navigateToPlay(
    List<String> categories,
    int timerSeconds,
    int totalQuestions,
  ) {
    if (!mounted) return;
    final params = <String, String>{
      'mode': widget.mode,
      'p1': widget.p1,
      'p2': widget.p2,
      'categories': categories.join(','),
      'timer': timerSeconds.toString(),
      'totalQuestions': totalQuestions.toString(),
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
        final questions = getRandomQuestions(
          _selectedCategories,
          totalQuestions,
        );
        final qList = questions
            .map((q) => {'text': q.text, 'category': q.category})
            .toList();

        await FirestoreService.updateGameConfig(
          widget.roomCode!,
          _selectedCategories,
          _timerEnabled ? _timerSeconds : 0,
          totalQuestions,
          questions: qList,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al iniciar juego: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canStart =
        _selectedCategories.isNotEmpty &&
        !_loading &&
        !(widget.mode == 'online' && !widget.isHost);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/pairing'),
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 20,
                  ),

                  Text("Volver"),
                ],
              ),
              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Configuren su ", style: TextStyle(fontSize: 24)),
                  Row(
                    children: [
                      Text(
                        "Partida ",
                        style: TextStyle(
                          color: Color(0xFFFF5C95),
                          fontSize: 24,
                        ),
                      ),

                      Icon(
                        Icons.favorite_border,
                        color: Colors.pinkAccent,
                        size: 24,
                      ),
                    ],
                  ),
                  Text(
                    "Elige las categorias y opciones para su juego",
                    //"${widget.p1} 💕 ${widget.p2}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // -------------------------Perfiles-------------------------------------
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF17121C),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFFF5C95).withOpacity(.25),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5C95).withOpacity(.10),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 24),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5C95).withOpacity(.15),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFD3E3), // Rosa claro arriba
                                Color(0xFFFF8FB7), // Rosa medio
                                Color(0xFFFF5C95), // Rosa intenso abajo
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            widget.p1[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 18),
                    Text(widget.p1, style: TextStyle(fontSize: 18)),
                    Spacer(),
                    Icon(
                      Icons.favorite_border,
                      color: Colors.pinkAccent,
                      size: 24,
                    ),
                    Spacer(),
                    Text(widget.p2, style: TextStyle(fontSize: 18)),
                    SizedBox(width: 18),

                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5C95).withOpacity(.15),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFD3E3), // Rosa claro arriba
                                Color(0xFFFF8FB7), // Rosa medio
                                Color(0xFFFF5C95), // Rosa intenso abajo
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            widget.p2[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                  ],
                ),
              ),
              // -------------------------------------Categories-------------------------------
              SizedBox(height: 12),
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
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text(
                            "        Seleccionen las categorias que quieren jugar",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                                // ignore: deprecated_member_use
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,

                          itemCount: categories.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.05,
                              ),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final selected = _selectedCategories.contains(
                              cat.id,
                            );

                            return _CategoryCard(
                              category: cat,
                              selected: selected,
                              isPremium: _isPremium,
                              onTap: () => _toggleCategory(cat.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      const SizedBox(height: 32),

                      // Timer
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xff151019),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF5C95,
                                    ).withOpacity(.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.timer_outlined,
                                    color: Color(0xFFFF5C95),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Temporizador",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _timerEnabled
                                            ? "Activado"
                                            : "Desactivado",
                                        style: TextStyle(
                                          color: _timerEnabled
                                              ? const Color(0xFFFF5C95)
                                              : Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        "Limita el tiempo por pregunta",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(.55),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Switch(
                                  activeTrackColor: Colors.pinkAccent,
                                  activeThumbColor: Colors.white,
                                  value: _timerEnabled,
                                  onChanged: (v) {
                                    setState(() {
                                      _timerEnabled = v;
                                    });
                                  },
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),

                              crossFadeState: _timerEnabled
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,

                              firstChild: const SizedBox(),

                              secondChild: Column(
                                children: [
                                  const SizedBox(height: 6),

                                  Text(
                                    "$_timerSeconds segundos",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.pinkAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        "10s",
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context)
                                              .copyWith(
                                                activeTrackColor: const Color(
                                                  0xFFFF5C95,
                                                ),

                                                inactiveTrackColor:
                                                    Colors.white10,

                                                thumbColor: const Color(
                                                  0xFFFF5C95,
                                                ),

                                                overlayColor: const Color(
                                                  0x22FF5C95,
                                                ),

                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 10,
                                                    ),

                                                trackHeight: 3,
                                              ),

                                          child: Slider(
                                            value: _timerSeconds.toDouble(),

                                            min: 10,

                                            max: 120,

                                            divisions: 22,

                                            onChanged: (v) {
                                              setState(() {
                                                _timerSeconds = v.toInt();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "120s",
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4F93), Color(0xFFFF6DA8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4F93).withOpacity(.35),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: canStart ? _startGame : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: canStart
                          ? const Color(0xFFFF5C95)
                          : Colors.grey.shade800,
                      foregroundColor: canStart ? Colors.white : Colors.white54,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.white54,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.favorite_border,
                            size: 24,
                            color: Colors.white,
                          ),
                    label: Text(
                      widget.mode == 'online' && !widget.isHost
                          ? "Esperando al anfitrión..."
                          : "¡Empezar! 🔥",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool selected;
  final bool isPremium;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF5C95);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          color: const Color(0xff151019),

          border: Border.all(
            color: selected ? pink : Colors.white.withOpacity(.10),
            width: selected ? 2 : 1,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: pink.withOpacity(.25),
                    blurRadius: 25,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),

        child: Stack(
          children: [
            if (selected)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(category.id), color: pink, size: 36),

                const Spacer(),

                Text(
                  category.label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _subtitle(category.id),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.65),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _icon(String id) {
  switch (id) {
    case "romance":
      return Icons.favorite_outline;

    case "divertido":
      return Icons.sentiment_satisfied_alt_outlined;

    case "hot":
      return Icons.local_fire_department_outlined;

    case "personal":
      return Icons.psychology_outlined;

    case "retos":
      return Icons.star_border;

    case "random":
      return Icons.chat_bubble_outline;

    default:
      return Icons.category_outlined;
  }
}

String _subtitle(String id) {
  switch (id) {
    case "romance":
      return "Conversaciones románticas";

    case "divertido":
      return "Preguntas divertidas";

    case "hot":
      return "Para subir la temperatura";

    case "personal":
      return "Conocimientos profundos";

    case "retos":
      return "Desafíos para parejas";

    case "random":
      return "Mezcla de todo un poco";

    default:
      return "";
  }
}
