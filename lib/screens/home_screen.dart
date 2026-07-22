import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _bgTop = Color(0xFF1A0914);
const Color _bgBottom = Color(0xFF0D0D0D);
const Color _pink = Color(0xFFFF2E93);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 16),
                const _WelcomeSection(),
                const SizedBox(height: 16),
                const _PlayButton(),

                const SizedBox(height: 18),
                const _StatsCard(),
                const SizedBox(height: 18),
                const _QuestionOfTheDayCard(),
                const SizedBox(height: 18),
                const _ContinueYourHistory(),
                const SizedBox(height: 20),
                const _AccesFast(),
                const SizedBox(height: 20),
                //  const _ProgressBanner(),
                // const SizedBox(height: 20),
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
              Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    const TextSpan(text: "Cada conversación\nfortalece su "),
                    TextSpan(
                      text: "historia 💗",
                      style: TextStyle(
                        color: const Color(0xFFE91E63),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
              height: 130,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/pairing'),
        child: Container(
          width: double.infinity,
          height: 155,

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_pink, Color(0xFFFF6B6B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _pink.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            children: [
              // ❤️ Corazón
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // Texto
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "¿Listos para una nueva\nconversación?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Descubran algo nuevo juntos.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .70),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "JUGAR AHORA",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Flecha
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFE91E63),
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── C. Stats Row ───────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(70, 14, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(width: 16),

              /// Lado izquierdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Racha actual",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),

                    SizedBox(height: 2),

                    Text(
                      "1 día",
                      style: TextStyle(
                        color: _pink,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      "¡Sigue así! 🔥",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 1),
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 120, color: Colors.white10),

              SizedBox(width: 20),

              /// Lado derecho
              SizedBox(
                width: 70,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withValues(alpha: .25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [Color(0xFF3D1730), Color(0xFF181220)],
                    ),

                    border: Border.all(
                      color: _pink.withValues(alpha: .6),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'lib/assets/images/icon_mensage.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Preguntas respondidas",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "270",
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Sigan así, lo están haciendo genial.",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _pink.withValues(alpha: .25),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
              gradient: RadialGradient(
                colors: [Color(0xFF3D1730), Color(0xFF181220)],
              ),

              border: Border.all(color: _pink.withValues(alpha: .6), width: 2),
            ),
            child: Image.asset(
              'lib/assets/images/icon_racha.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

// ───Question of the Day Card ─────────────────────────────────────────────────────

class _QuestionOfTheDayCard extends StatelessWidget {
  const _QuestionOfTheDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icono + título
          Row(
            children: [
              Image.asset(
                "lib/assets/images/icon_questionsOfDay.png",
                width: 60,
                height: 60,
              ),

              const SizedBox(width: 14),

              const Text(
                "Pregunta del día",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            "¿Cuál es tu recuerdo favorito juntos?",
            style: TextStyle(color: Colors.white, fontSize: 17, height: 1.4),
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () {},

              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _pink.withValues(alpha: .5)),

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text("Responder", style: TextStyle(color: Color(0xFFE91E63))),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFFE91E63),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ContinueYourHistory ───────────────────────────────────────────────────────────
class _ContinueYourHistory extends StatelessWidget {
  const _ContinueYourHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.heart_broken, color: Colors.orange, size: 26),
          SizedBox(width: 16),

          /// Lado izquierdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Continúa su historia",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 2),

                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 13),
                    children: [
                      TextSpan(text: "Tienen "),
                      TextSpan(
                        text: "12 recuerdos ",
                        style: TextStyle(color: const Color(0xFFE91E63)),
                      ),
                      TextSpan(text: "guardados "),
                    ],
                  ),
                ),
                Text(
                  "Sigan creando momentos inolvidables",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          SizedBox(width: 20),

          /// Lado derecho
          Icon(Icons.arrow_right_alt, color: Colors.deepPurpleAccent, size: 26),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ─── Acceso Rapido     ─────────────────────────────────────────────────────
class _AccesFast extends StatelessWidget {
  const _AccesFast();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Accesos rápidos",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        SizedBox(
          height: 185,
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),

              itemCount: 4,

              separatorBuilder: (_, __) => const SizedBox(width: 14),

              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return SizedBox(
                      width: 145,
                      child: _QuickCard(
                        route: "/nuestraHistoria",
                        title: "Historia",
                        subtitle: "Recuerdos y\nmomentos",
                        image: Image.asset(
                          "lib/assets/images/icon_history.png",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        imageColor: _pink,
                        startColor: const Color(0xFF511B39),
                        endColor: const Color(0xFF261320),
                      ),
                    );

                  case 1:
                    return SizedBox(
                      width: 145,
                      child: _QuickCard(
                        route: "/achievements",
                        title: "Logros",
                        subtitle: "Desbloquea y\nsigue tu progreso",
                        image: Image.asset(
                          "lib/assets/images/icon_logros.png",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        imageColor: Colors.orange,
                        startColor: const Color(0xFF4A2913),
                        endColor: const Color(0xFF261813),
                      ),
                    );

                  case 2:
                    return SizedBox(
                      width: 145,
                      child: _QuickCard(
                        route: "/ai",
                        title: "LoveQuiz IA",
                        subtitle: "Preguntas\npersonalizadas",
                        image: Image.asset(
                          "lib/assets/images/icon_ia.png",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        imageColor: Colors.deepPurpleAccent,
                        startColor: const Color(0xFF321A57),
                        endColor: const Color(0xFF1D1531),
                      ),
                    );

                  default:
                    return SizedBox(
                      width: 145,
                      child: _QuickCard(
                        route: "/premium",
                        title: "Premium",
                        subtitle: "Desbloquea todo\nel potencial",
                        image: Image.asset(
                          "lib/assets/images/icon_premium.png",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        imageColor: Colors.lightBlueAccent,
                        startColor: const Color(0xFF19345E),
                        endColor: const Color(0xFF16233E),
                      ),
                    );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final Image image;
  final String title;
  final String subtitle;

  final Color imageColor;
  final Color startColor;
  final Color endColor;
  final String route;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.imageColor,
    required this.startColor,
    required this.endColor,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),

          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [startColor, endColor],
          ),

          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),

        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: imageColor.withValues(alpha: .15),

                boxShadow: [
                  BoxShadow(
                    color: imageColor.withValues(alpha: .25),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: Center(child: image),
            ),

            const Spacer(),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
