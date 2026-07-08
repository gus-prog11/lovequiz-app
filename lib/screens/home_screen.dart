import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _bgTop = Color(0xFF1A0914);
const Color _bgBottom = Color(0xFF0D0D0D);
const Color _pink = Color(0xFFFF2E93);
const Color _gold = Color(0xFFFFD700);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 16),
                const _WelcomeSection(),
                const SizedBox(height: 24),
                const _StatsRow(),
                const SizedBox(height: 24),
                const _PlayButton(),
                const SizedBox(height: 28),
                const _ExploreSection(),
                const SizedBox(height: 20),
                const _ProgressBanner(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── A. Header ──────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _pink, size: 18),
              const SizedBox(width: 6),
              Text(
                "LoveQuiz",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "3",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── B. Welcome + Heart ─────────────────────────────────────────────────────
class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hola, Gus 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Cada conversación \n fortalece su historia 💗",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            Image.asset(
              'lib/assets/images/hearts_home.png',
              width: 220,
              height: 150,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── D. Play Button ─────────────────────────────────────────────────────────
class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pairing'),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_pink, Color(0xFFFF6B6B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _pink.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 10),

            const Icon(Icons.favorite, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Text(
              "Jugar Ahora",

              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── C. Stats Row ───────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: "1 día",
            label: "¡Sigue así!",
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            iconColor: _gold,
            value: "7",
            label: "Desbloqueados",
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatCard(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.cyan,
            value: "270",
            label: "Respondidas",
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month,
            iconColor: _pink,
            value: "Jun 2026",
            label: "Miembro",
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// ─── E. Explore Section ─────────────────────────────────────────────────────
class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: _pink, size: 16),
                const SizedBox(width: 6),
                const Text(
                  "Explora LoveQuiz",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              "Ver todo >",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _FeatureGrid(),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.favorite,
                iconColor: _pink,
                title: "Nuestra Historia",
                subtitle: "12 recuerdos",
                route: '/nuestraHistoria',
                showArrow: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FeatureCard(
                icon: Icons.people,
                iconColor: Colors.purple.shade300,
                title: "Social",
                subtitle: "0 amigos",
                route: '/social',
                showArrow: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.emoji_events,
                iconColor: _gold,
                title: "Logros y Rachas",
                subtitle: "7 logros",
                route: '/achievements',
                showArrow: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FeatureCard(
                icon: Icons.auto_awesome,
                iconColor: Colors.purple.shade400,
                title: "LoveQuiz IA",
                subtitle: "",
                route: '/ai',
                isNew: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.calendar_today,
                iconColor: Colors.teal.shade300,
                title: "Pregunta del día",
                subtitle: "¡Responde ahora!",
                route: '',
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade800.withValues(alpha: 0.4),
                    Colors.blue.shade900.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FeatureCard(
                icon: Icons.card_giftcard,
                iconColor: _pink,
                title: "Sorpresa diaria",
                subtitle: "Disponible",
                route: '',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String route;
  final bool showArrow;
  final bool isNew;
  final Gradient? gradient;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.route,
    this.showArrow = false,
    this.isNew = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route.isNotEmpty ? () => context.push(route) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white.withValues(alpha: 0.05) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isNew) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _pink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Nuevo",
                            style: TextStyle(
                              color: _pink,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (showArrow)
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white24,
                          size: 18,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── F. Progress Banner ─────────────────────────────────────────────────────
class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, color: _pink, size: 20),
          const SizedBox(width: 4),
          const Icon(Icons.favorite, color: _pink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sigan construyendo su historia ❤️",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Cada día es una oportunidad para conocerse mejor.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: _pink,
                  ),
                ),
                Text(
                  "75%",
                  style: TextStyle(
                    color: _pink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
