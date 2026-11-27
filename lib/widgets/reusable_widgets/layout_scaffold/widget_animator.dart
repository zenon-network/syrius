import 'dart:async';

import 'package:flutter/material.dart';

/// Animates a [child] widget with a delayed fade-in and upward slide.
class WidgetAnimator extends StatefulWidget {
  /// Creates a [WidgetAnimator].
  const WidgetAnimator({
    required this.child,
    this.animationOffset = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
    super.key,
  });

  /// Widget animated into view.
  final Widget? child;

  /// Duration of the fade and slide animation.
  final Duration duration;

  /// Easing curve applied to the animation.
  final Curve curve;

  /// Delay before starting the entrance animation.
  final Duration animationOffset;

  @override
  State<WidgetAnimator> createState() => _WidgetAnimatorState();
}

class _WidgetAnimatorState extends State<WidgetAnimator>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: widget.curve,
    );
    _timer = Timer(
      widget.animationOffset,
      _animationController!.forward,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              (1.0 - _animation.value) * 20.0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
