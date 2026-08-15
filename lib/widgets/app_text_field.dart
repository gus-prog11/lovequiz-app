import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Campo de texto con el estilo de los formularios de login/registro:
/// borde redondeado, icono de prefijo, foco rosa y (opcional) botón para
/// mostrar/ocultar la contraseña.
///
/// Centraliza la ~20 líneas de decoración que se duplicaban en cada campo.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.15);
    final iconColor = isLight ? ac.textSecondary : Colors.white54;
    final labelColor = isLight
        ? ac.textMuted
        : Colors.white.withValues(alpha: 0.4);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: TextStyle(color: ac.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        filled: true,
        fillColor: isLight
            ? Colors.grey.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.pink, width: 1.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        prefixIcon: Icon(prefixIcon, color: iconColor),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
    );
  }
}
