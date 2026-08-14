import 'package:flutter/material.dart';
import '../config/app_colors.dart';

const Color _pink = AppColors.pink;

/// Botón-cara para reaccionar en las revelaciones.
///
/// Diseño de interacción sutil: una cara que, al tocarla, expande el menú de
/// reacciones. Al elegir una, la reacción aparece animada en el MISMO sitio
/// (tanto la propia como la que llega de la pareja en línea); la pantalla la
/// oculta a los pocos segundos volviendo `reactionEmoji` a null.
class ReactionButton extends StatefulWidget {
  final ValueChanged<String> onReact;

  /// Reacción visible en este instante (propia o de la pareja). null = cara.
  final String? reactionEmoji;

  const ReactionButton({
    super.key,
    required this.onReact,
    this.reactionEmoji,
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
        // La cara (o la reacción) en el mismo sitio.
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
