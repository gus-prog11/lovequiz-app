import 'package:flutter/material.dart';

class PairOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Image image;
  final Color accentColor;
  final bool highlighted;
  final VoidCallback onTap;

  const PairOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.accentColor,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: highlighted
                ? LinearGradient(
                    colors: [
                      accentColor.withOpacity(.9),
                      accentColor.withOpacity(.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(.08),
                      Colors.white.withOpacity(.02),
                    ],
                  ),
          ),
          padding: const EdgeInsets.all(1.3),
          child: AnimatedScale(
            scale: highlighted ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xff151219),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.transparent, width: 1.3),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: highlighted
                              ? accentColor.withOpacity(.35)
                              : Colors.black.withOpacity(.25),
                          blurRadius: highlighted ? 28 : 12,
                          spreadRadius: highlighted ? 2 : 0,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Icono izquierdo
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: highlighted
                            ? accentColor
                            : Colors.white.withOpacity(.08),
                      ),
                    ),
                    child: Image(
                      image: image.image,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 22),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white.withOpacity(.7),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Flecha
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: highlighted ? accentColor : Colors.white24,
                      ),
                      boxShadow: highlighted
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(.4),
                                blurRadius: 18,
                              ),
                            ]
                          : [],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: highlighted
                            ? accentColor.withOpacity(.08)
                            : Colors.transparent,
                        border: Border.all(
                          color: highlighted
                              ? accentColor.withOpacity(.7)
                              : Colors.white10,
                        ),
                      ),

                      child: Icon(
                        Icons.chevron_right,
                        color: accentColor,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
