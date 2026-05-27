import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class QuickPlayCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const QuickPlayCard({
    super.key,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<QuickPlayCard> createState() => _QuickPlayCardState();
}

class _QuickPlayCardState extends State<QuickPlayCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isPressed ? Matrix4.translationValues(0, 2, 0) : Matrix4.identity(),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.colors.first.withOpacity(0.3),
              blurRadius: _isPressed ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(widget.icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
