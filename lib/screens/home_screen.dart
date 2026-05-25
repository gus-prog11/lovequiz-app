import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _floatingEmojis = ["💕", "🔥", "😂", "😳", "⚡"];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                // Logo area
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.pink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Para parejas",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Main Title
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Colors.pink.shade300,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            "LoveQuiz",
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Conéctense, diviértanse y fortalezcan su relación con preguntas y retos 💕",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Floating hearts animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_floatingEmojis.length, (index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 1500 + (index * 200)),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, -8 * (1 - (value * 2 - 1).abs())),
                            child: Text(
                              _floatingEmojis[index],
                              style: const TextStyle(fontSize: 28),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                const Spacer(),

                // Action buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Jugar Ahora button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/pairing'),
                          icon: const Icon(Icons.favorite, size: 20),
                          label: const Text(
                            "Jugar Ahora",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Secondary buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/pairing?mode=local'),
                              icon: const Icon(Icons.smartphone, size: 18),
                              label: const Text(
                                "Mismo Teléfono",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/pairing?mode=online'),
                              icon: const Icon(Icons.bolt, size: 18),
                              label: const Text(
                                "En Línea",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Premium button
                      TextButton.icon(
                        onPressed: () => context.push('/premium'),
                        icon: const Icon(
                          Icons.workspace_premium,
                          size: 18,
                          color: Colors.amber,
                        ),
                        label: const Text(
                          "Premium — Sin límites",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Hecho con 💖 para parejas que quieren más",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
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
