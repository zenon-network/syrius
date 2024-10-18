import 'dart:async';

import 'package:flutter/material.dart';

class WidgetAnimator extends StatefulWidget {

  const WidgetAnimator({
    required this.child,
    this.animationOffset = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
    super.key,
  });
  final Widget? child;
  final Duration duration;
  final Curve curve;
  final Duration animationOffset;

  @override
  State<WidgetAnimator> createState() => _WidgetAnimatorState();
}

class _WidgetAnimatorState extends State<WidgetAnimator>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation? _animation;
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
      animation: _animation!,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _animation!.value,
          child: Transform.translate(
            offset: Offset(
              0,
              (1.0 - _animation!.value) * 20.0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
