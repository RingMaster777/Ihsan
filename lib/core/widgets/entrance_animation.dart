import 'dart:async';

import 'package:flutter/material.dart';

/// Plays a one-time fade + slide (+ optional scale) when first inserted.
///
/// Unlike effect chains that can restart on rebuild, this only runs in
/// `initState`, so parents can call `setState` freely.
class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.08),
    this.scaleBegin = 1,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Start offset as a fraction of the child's size.
  final Offset offset;
  final double scaleBegin;
  final Curve curve;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _motion =
      CurvedAnimation(parent: _controller, curve: widget.curve);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;
    if (widget.scaleBegin != 1) {
      result = ScaleTransition(
        scale: Tween<double>(begin: widget.scaleBegin, end: 1).animate(_motion),
        child: result,
      );
    }
    if (widget.offset != Offset.zero) {
      result = SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_motion),
        child: result,
      );
    }
    return FadeTransition(opacity: _fade, child: result);
  }
}
