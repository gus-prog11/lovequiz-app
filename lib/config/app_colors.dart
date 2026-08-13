import 'package:flutter/material.dart';

// Paleta de colores adaptativa para modo claro/oscuro.
// Mantiene el branding rosa en ambos modos, ajustando fondos y textos.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderLight;
  final Color divider;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderLight,
    required this.divider,
  });

  // Colores para modo oscuro (actual diseño de la app).
  static const dark = AppColors(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF1A0914),
    surfaceAlt: Color(0xFF1E1528),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textMuted: Color(0xFF707070),
    border: Color(0x1AFFFFFF),
    borderLight: Color(0x0DFFFFFF),
    divider: Color(0x0FFFFFFF),
  );

  // Colores para modo claro (mantiene branding rosa pero fondos claros).
  // Fondo con tinte rosa cálido para que toda la app respire el branding,
  // en lugar del gris plano que se sentía frío y genérico.
  static const light = AppColors(
    background: Color(0xFFFBF1F4),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6E9EE),
    textPrimary: Color(0xFF241A1F),
    textSecondary: Color(0xFF6E5F66),
    textMuted: Color(0xFF9E8B93),
    border: Color(0x1F000000),
    borderLight: Color(0x0D000000),
    divider: Color(0x14000000),
  );

  // Color rosa del branding (igual en ambos modos).
  static const pink = Color(0xFFFF2E93);

  /// Extremo del gradiente de marca (rosa → rosa claro/coral). Usado por los
  /// CTA y tarjetas principales; evita inventar tonos rosas sueltos.
  static const pinkGradientEnd = Color(0xFFFF6A8E);

  static const gold = Color(0xFFFFD700);
  static const purple = Color(0xFFB8439F);
  static const cyan = Color(0xFF00D4FF);

  // Obtiene los colores según el modo actual. Devuelve la extensión del tema
  // (que interpola durante la animación de tema) para que el cambio entre
  // modo claro y oscuro sea fluido; si no hay extensión, decide por brightness.
  static AppColors of(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    if (colors != null) return colors;
    return Theme.of(context).brightness == Brightness.light ? light : dark;
  }

  @override
  ThemeExtension<AppColors> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderLight,
    Color? divider,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
