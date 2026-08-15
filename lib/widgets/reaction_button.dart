import 'package:flutter/material.dart';
import '../config/app_colors.dart';

const Color _pink = AppColors.pink;

/// Botón-cara para reaccionar en las revelaciones.
///
/// Diseño de interacción sutil: una cara que, al tocarla, expande el menú de
/// reacciones. Al elegir una, la reacción propia aparece animada en el MISMO
/// sitio (dentro del botón); la reacción que llega de la pareja en línea se
/// muestra FUERA del botón, en una burbuja a su izquierda. La pantalla las
/// oculta a los pocos segundos volviendo los emojis a null.
class ReactionButton extends StatefulWidget {
  final ValueChanged<String> onReact;

  /// Reacción propia visible en este instante. null = cara.
  final String? reactionEmoji;

  /// Reacción que llega de la pareja en línea. null = no hay reacción.
  final String? partnerReactionEmoji;

  /// Nombre de la pareja, etiqueta bajo la burbuja izquierda.
  final String? partnerName;

  const ReactionButton({
    super.key,
    required this.onReact,
    this.reactionEmoji,
    this.partnerReactionEmoji,
    this.partnerName,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  static const List<String> _emojis = ['❤️', '😂', '🥰', '😮', '🔥', '👏'];
  static const String _faceEmoji = '🙂';

  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _pick(String emoji) {
    setState(() => _expanded = false);
    widget.onReact(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final reaction = widget.reactionEmoji;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menú de reacciones que se expande al tocar la cara.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: !_expanded
              ? const SizedBox.shrink(key: ValueKey('closed'))
              : Container(
                  key: const ValueKey('open'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ac.surfaceAlt,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _pink.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _emojis.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _EmojiOption(
                          emoji: _emojis[i],
                          onTap: () => _pick(_emojis[i]),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        // Reacción de la pareja (burbuja a la izquierda) y cara propia.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPartnerReaction(ac),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.pink.withValues(alpha: 0.9),
                      AppColors.pinkGradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _pink.withValues(alpha: 0.3),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: Tween(begin: 0.4, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: reaction == null
                        ? const Text(
                            _faceEmoji,
                            key: ValueKey('face'),
                            style: TextStyle(fontSize: 30),
                          )
                        : Text(
                            reaction,
                            key: ValueKey('reaction$reaction'),
                            style: const TextStyle(fontSize: 34),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Burbuja animada con la reacción de la pareja, fuera del botón y a su
  /// izquierda. Se oculta cuando `partnerReactionEmoji` vuelve a null.
  Widget _buildPartnerReaction(AppColors ac) {
    final emoji = widget.partnerReactionEmoji;
    if (emoji == null) return const SizedBox.shrink();

    final name = widget.partnerName;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: Column(
        key: ValueKey('partner_$emoji'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ac.surfaceAlt,
              border: Border.all(
                color: _pink.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          if (name != null && name.isNotEmpty) ...[
            const SizedBox(height: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 64),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _pink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmojiOption extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiOption({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}
