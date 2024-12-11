// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

Path _downTriangle(double size, Offset thumbCenter, {bool invert = false}) {
  final Path thumbPath = Path();
  final double height = math.sqrt(3) / 2.0;
  final double centerHeight = size * height / 3.0;
  final double halfSize = size / 2.0;
  final double sign = invert ? -1.0 : 1.0;
  thumbPath.moveTo(
    thumbCenter.dx - halfSize,
    thumbCenter.dy + sign * centerHeight,
  );
  thumbPath.lineTo(
    thumbCenter.dx,
    thumbCenter.dy - 2 * sign * centerHeight,
  );
  thumbPath.lineTo(
    thumbCenter.dx + halfSize,
    thumbCenter.dy + sign * centerHeight,
  );
  thumbPath.close();
  return thumbPath;
}

Path _upTriangle(double size, Offset thumbCenter) =>
    _downTriangle(size, thumbCenter, invert: true);

class _CustomThumbShape extends SliderComponentShape {
  const _CustomThumbShape();

  static const double _thumbSize = 4;
  static const double _disabledThumbSize = 3;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return isEnabled
        ? const Size.fromRadius(_thumbSize)
        : const Size.fromRadius(_disabledThumbSize);
  }

  static final Animatable<double> sizeTween = Tween<double>(
    begin: _disabledThumbSize,
    end: _thumbSize,
  );

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    required Animation<double> enableAnimation, required SliderThemeData sliderTheme, Animation<double>? activationAnimation,
    bool? isDiscrete,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final double size = _thumbSize * sizeTween.evaluate(enableAnimation);
    final Path thumbPath = _downTriangle(size, thumbCenter);
    canvas.drawPath(
      thumbPath,
      Paint()..color = colorTween.evaluate(enableAnimation)!,
    );
  }
}

class _CustomValueIndicatorShape extends SliderComponentShape {
  const _CustomValueIndicatorShape();

  static const double _indicatorSize = 4;
  static const double _disabledIndicatorSize = 3;
  static const double _slideUpHeight = 40;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled ? _indicatorSize : _disabledIndicatorSize);
  }

  static final Animatable<double> sizeTween = Tween<double>(
    begin: _disabledIndicatorSize,
    end: _indicatorSize,
  );

  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required TextPainter labelPainter, required SliderThemeData sliderTheme, bool? isDiscrete,
    RenderBox? parentBox,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );
    final Tween<double> slideUpTween = Tween<double>(
      begin: 0,
      end: _slideUpHeight,
    );
    final double size = _indicatorSize * sizeTween.evaluate(enableAnimation);
    final Offset slideUpOffset =
        Offset(0, -slideUpTween.evaluate(activationAnimation));
    final Path thumbPath = _upTriangle(size, thumbCenter + slideUpOffset);
    final Color paintColor = enableColor
        .evaluate(enableAnimation)!
        .withAlpha((255.0 * activationAnimation.value).round());
    canvas.drawPath(
      thumbPath,
      Paint()..color = paintColor,
    );
    canvas.drawLine(
        thumbCenter,
        thumbCenter + slideUpOffset,
        Paint()
          ..color = paintColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,);
    labelPainter.paint(
      canvas,
      thumbCenter +
          slideUpOffset +
          Offset(-labelPainter.width / 2.0, -labelPainter.height - 4.0),
    );
  }
}

class CustomSlider extends StatefulWidget {

  const CustomSlider({
    required this.description,
    required this.startValue,
    required this.maxValue,
    required this.callback,
    this.min = 1.0,
    this.activeColor = AppColors.znnColor,
    super.key,
  });
  final String description;
  final double? startValue;
  final double maxValue;
  final Function callback;
  final double min;
  final Color activeColor;

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  double? _discreteCustomValue;

  @override
  Widget build(BuildContext context) {
    _discreteCustomValue ??= widget.startValue;

    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SliderTheme(
              data: theme.sliderTheme.copyWith(
                trackHeight: 2,
                activeTrackColor: widget.activeColor,
                inactiveTrackColor:
                    theme.colorScheme.onSurface.withOpacity(0.5),
                activeTickMarkColor:
                    theme.colorScheme.onSurface.withOpacity(0.7),
                inactiveTickMarkColor:
                    theme.colorScheme.surface.withOpacity(0.7),
                overlayColor: theme.colorScheme.onSurface.withOpacity(0.12),
                thumbColor: widget.activeColor,
                valueIndicatorColor: widget.activeColor,
                thumbShape: const _CustomThumbShape(),
                valueIndicatorShape: const _CustomValueIndicatorShape(),
                valueIndicatorTextStyle: theme.textTheme.bodyLarge!.copyWith(
                  color: Colors.white,
                ),
              ),
              child: Slider(
                inactiveColor: AppColors.maxAmountBorder,
                value: _discreteCustomValue!,
                min: widget.min,
                max: widget.maxValue,
                divisions: (widget.maxValue - widget.min).toInt(),
                semanticFormatterCallback: (double value) => value.round().toString(),
                label: '${_discreteCustomValue!.round()}',
                onChanged: (double value) {
                  setState(() {
                    _discreteCustomValue = value;
                    widget.callback(value);
                  });
                },
              ),
            ),
            Text(
              widget.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
