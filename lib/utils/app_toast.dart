import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Toast tipo Instagram: aparece desde arriba, se auto-oculta, se reinicia
/// cada vez que se muestra uno nuevo. No bloquea la interacción.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Muestra un toast con [message] y tipo [type].
  ///
  /// Si ya hay un toast visible se oculta primero y se muestra el nuevo
  /// (reiniciando el temporizador de auto-dismiss).
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(message: message, type: type),
    );
    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
      entry.remove();
      _currentEntry = null;
    });
  }

  static void showSuccess(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.success);

  static void showError(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.error);

  static void showInfo(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.info);

  static void showWarning(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.warning);
}

enum AppToastType { success, error, info, warning }

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({required this.message, required this.type});

  final String message;
  final AppToastType type;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case AppToastType.success:
        return const Color(0xFF1B5E20);
      case AppToastType.error:
        return AppColors.danger;
      case AppToastType.warning:
        return AppColors.warning;
      case AppToastType.info:
        return const Color(0xFF1A1A2E);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_outline;
      case AppToastType.error:
        return Icons.error_outline;
      case AppToastType.warning:
        return Icons.warning_amber_rounded;
      case AppToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      top: topPadding,
      left: 48,
      right: 48,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
