import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;

  const AppButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.enabled = true,
  });

  static const Color _pink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors:[   Color(0xFFFF4F8A),
        Color(0xFFFFA164)]),
          boxShadow: [BoxShadow(color: _pink.withOpacity(.35), blurRadius: 20)],
        ),
        child: FilledButton.icon(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
          label: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      
    );
  }
}
