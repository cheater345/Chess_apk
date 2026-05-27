import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class HomeCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HomeCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
