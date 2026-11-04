import 'package:flutter/material.dart';

/// Counts up from 0 on first build and smoothly retargets when [value] changes.
///
/// By default the running value is rounded to a whole number; pass [format]
/// (e.g. `formatPoints`) when a value can carry halves.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
    this.format,
  });

  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextAlign? textAlign;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$prefix${format != null ? format!(v) : v.round()}$suffix',
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
