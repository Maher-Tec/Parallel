import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A luminous, tactile primary action for entering Holmi's dream space.
class DreamButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const DreamButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<DreamButton> createState() => _DreamButtonState();
}

class _DreamButtonState extends State<DreamButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pressed
                ? const [Color(0xFFB8914D), Color(0xFFCFAB63)]
                : const [Color(0xFFE5C77F), AppTheme.accent, Color(0xFFB88F4B)],
          ),
          border: Border.all(color: const Color(0xFFFFE9B2).withAlpha(150)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withAlpha(_pressed ? 34 : 72),
              blurRadius: _pressed ? 16 : 30,
              spreadRadius: _pressed ? 0 : 1,
              offset: Offset(0, _pressed ? 4 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF211B10),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(widget.icon, color: const Color(0xFF211B10), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
