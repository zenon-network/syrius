import 'package:flutter/material.dart';

class NumberAnimation extends StatefulWidget {

  /// constructor
  NumberAnimation({
    super.key,
    this.start = 0.0,
    this.end,
    this.isInt = false,
    this.style,
    this.textAlign,
    this.strutStyle,
    this.duration = const Duration(milliseconds: 1000),
    this.decimalPoint = 2,
    this.before = '',
    this.after = '',
    this.isLoading = false,
    this.loadingPlaceHolder = '',
  }) {
    if (isLoading == false) {
      assert(end != null);
      if (isInt) {
        assert(start.toInt() == start);
        assert(end!.toInt() == end);
      }
    }
  }
  /// start number
  final num start;

  /// end number
  final num? end;

  /// true for int, false for double
  final bool isInt;

  /// animation duration
  final Duration duration;

  /// TextStyle
  final TextStyle? style;

  /// TextAlign
  final TextAlign? textAlign;

  /// StrutStyle
  final StrutStyle? strutStyle;

  /// number prefix
  final String before;

  /// number suffix
  final String after;

  /// decimal point
  final int decimalPoint;

  /// is on loading?
  final bool isLoading;

  /// loading placeholder
  final String loadingPlaceHolder;

  /// create state
  @override
  State<NumberAnimation> createState() => _NumberAnimationState();
}

/// state
class _NumberAnimationState extends State<NumberAnimation>
    with SingleTickerProviderStateMixin {
  Animation? _animation;
  late Animation _curve;
  bool _hasShowNumber = false; // has been show once
  AnimationController? controller;

  // initState
  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: widget.duration, vsync: this);
    _curve = CurvedAnimation(parent: controller!, curve: Curves.easeOut);
    if (widget.isLoading == false) {
      final animation = Tween<double>(
              begin: widget.start.toDouble(), end: widget.end!.toDouble(),)
          .animate(_curve as Animation<double>);
      _animation = animation;
      controller!.forward();
      _hasShowNumber = true;
    }
  }

  /// dispose
  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  // didUpdateWidget
  @override
  void didUpdateWidget(NumberAnimation oldWidget) {
    if (widget.isLoading == true) {
      return;
    }
    if (oldWidget.end == widget.end && _hasShowNumber == true) {
      return;
    }
    final animation = Tween<double>(
            begin: _animation != null
                ? _animation!.value
                : widget.start.toDouble(),
            end: widget.end!.toDouble(),)
        .animate(_curve as Animation<double>);
    _animation = animation;
    controller!
      ..reset()
      ..forward();
    _hasShowNumber = true;
    super.didUpdateWidget(oldWidget);
  }

  /// build
  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final textAlign = widget.textAlign;
    final strutStyle = widget.strutStyle;
    if (widget.isLoading == true) {
      return Text(
        widget.loadingPlaceHolder,
        style: style,
        textAlign: textAlign,
        strutStyle: strutStyle,
      );
    }
    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        if (widget.isLoading == true) {
          return Text(
            widget.loadingPlaceHolder,
            style: style,
            textAlign: textAlign,
            strutStyle: strutStyle,
          );
        }
        if (widget.isInt) {
          return Text(
            '${widget.before}${_animation!.value.toInt()}${widget.after}',
            style: style,
            textAlign: textAlign,
            strutStyle: strutStyle,
          );
        } else {
          return Text(
            '${widget.before}${_animation!.value.toStringAsFixed(widget.decimalPoint)}${widget.after}',
            style: style,
            textAlign: textAlign,
            strutStyle: strutStyle,
          );
        }
      },
    );
  }
}
