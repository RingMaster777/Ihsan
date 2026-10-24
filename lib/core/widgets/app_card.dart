import 'package:flutter/material.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';

/// Rounded, softly shadowed surface used throughout the app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.gradient,
    this.borderColor,
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? p.card : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.cardBorder.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
    if (onTap != null) card = PressableScale(onTap: onTap, child: card);
    return card;
  }
}
