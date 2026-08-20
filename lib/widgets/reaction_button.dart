import 'package:flutter/material.dart';
import '../config/app_colors.dart';

const Color _pink = AppColors.pink;

/// Botón-cara para reaccionar en las revelaciones.
///
/// Al tocar la cara se expande el menú de reacciones. Al elegir una, la
/// reacción propia aparece con animación de movimiento (wiggle + float) sin
/// contenedor circular. La reacción de la pareja aparece a su izquierda con
/// la misma animación. Ambas se ocultan a los pocos segundos.
class ReactionButton extends StatefulWidget {
  final ValueChanged<String> onReact;

  /// Reacción propia visible en este instante. null = cara.
  final String? reactionEmoji;

  /// Reacción que llega de la pareja en línea. null = no hay reacción.
  final String? partnerReactionEmoji;

  /// Nombre de la pareja, etiqueta bajo la reacción izquierda.
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
  static const List<String> _emojis = [
    '❤️',
    '😂',
    '🥰',
    '😮',
    '🔥',
    '👏',
    '😡',
  ];
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
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < _emojis.length; i++)
                        _EmojiOption(
                          emoji: _emojis[i],
                          onTap: () => _pick(_emojis[i]),
                        ),
                    ],
                  ),
                ),
        ),
        // Reacción de la pareja y cara propia.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPartnerReaction(ac),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: _toggle,
              child: SizedBox(
                width: 64,
                height: 64,
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
                        : _AnimatedEmoji(
                            key: ValueKey('reaction$reaction'),
                            emoji: reaction,
                            fontSize: 38,
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

  /// Reacción de la pareja: emoji flotante sin contenedor, con animación
  /// de movimiento. Se oculta cuando `partnerReactionEmoji` vuelve a null.
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
          _AnimatedEmoji(emoji: emoji, fontSize: 32),
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

/// Emoji animado que aparece con wiggle + float para simular un GIF
/// emocional. Repite la animación de forma continua mientras sea visible.
class _AnimatedEmoji extends StatefulWidget {
  final String emoji;
  final double fontSize;

  const _AnimatedEmoji({
    super.key,
    required this.emoji,
    this.fontSize = 32,
  });

  @override
  State<_AnimatedEmoji> createState() => _AnimatedEmojiState();
}

class _AnimatedEmojiState extends State<_AnimatedEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        // Wiggle horizontal (ida y vuelta)
        final dx = 3.0 * (t < 0.5 ? t * 2 : (1 - t) * 2) *
            (t < 0.25 || t > 0.75 ? 1 : -1);
        // Float vertical (sube y baja suavemente)
        final dy = -4.0 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        // Escala pulsante sutil
        final scale = 1.0 + 0.08 * (t < 0.5 ? t * 2 : (1 - t) * 2);

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Text(
              widget.emoji,
              style: TextStyle(fontSize: widget.fontSize),
            ),
          ),
        );
      },
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
