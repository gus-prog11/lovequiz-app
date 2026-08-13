import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Widget reutilizable que muestra un avatar circular de perfil con imagen o iniciales.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final String? fallbackText;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Widget? badge;
  final VoidCallback? onTap;

  // Constructor del avatar con tamaño requerido y opciones de personalización.
  const ProfileAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.fallbackText,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
    this.badge,
    this.onTap,
  });

  // Construye el widget avatar con imagen, badge y gesto opcional.
  @override
  Widget build(BuildContext context) {
    final radius = size / 2;

    final decorated = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A0914),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _buildContent(),
      ),
    );

    Widget result = decorated;

    if (badge != null) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          result,
          Positioned(
            bottom: -2,
            right: -2,
            child: badge!,
          ),
        ],
      );
    }

    if (onTap != null) {
      result = GestureDetector(onTap: onTap, child: result);
    }

    return result;
  }

  // Construye el contenido del avatar: imagen de red o fallback con iniciales.
  Widget _buildContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          color: const Color(0xFF1A0914),
          child: Icon(Icons.person, size: size * 0.5, color: Colors.white38),
        ),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  // Construye el fallback mostrando la primera letra del nombre o un signo de interrogación.
  Widget _buildFallback() {
    final initial = (fallbackText != null && fallbackText!.isNotEmpty)
        ? fallbackText![0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1A0914),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
