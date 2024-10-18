import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

enum ButtonState { busy, idle }

class LoadingButton extends StatefulWidget {

  const LoadingButton({
    required this.onPressed,
    required Key key,
    this.text,
    this.minimumSize = kLoadingButtonMinSize,
    this.minWidth = 0.0,
    this.child,
    this.outlineColor,
    this.paddingAroundChild = EdgeInsets.zero,
    this.borderWidth = kDefaultBorderOutlineWidth,
    this.circularBorderRadius = 6.0,
    this.textStyle,
  })  : assert(text != null || child != null),
        super(key: key);

  factory LoadingButton.infiniteScrollTableWithIcon({
    required VoidCallback? onPressed,
    required String text,
    required Key key,
    required Widget icon,
    TextStyle? textStyle,
    Color? outlineColor,
  }) =>
      LoadingButton.icon(
        onPressed: onPressed,
        label: text,
        key: key,
        minimumSize: const Size(90, 25),
        textStyle: textStyle,
        outlineColor: outlineColor,
        icon: icon,
      );

  factory LoadingButton.infiniteScrollTable({
    required VoidCallback? onPressed,
    required String text,
    required Key key,
    TextStyle? textStyle,
    Color? outlineColor,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        text: text,
        key: key,
        minimumSize: const Size(80, 25),
        textStyle: textStyle,
        outlineColor: outlineColor,
      );

  factory LoadingButton.settings({
    required VoidCallback? onPressed,
    required String text,
    required Key key,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        text: text,
        minimumSize: kSettingsButtonMinSize,
        key: key,
        textStyle: kBodyMediumTextStyle,
      );

  factory LoadingButton.onboarding({
    required VoidCallback? onPressed,
    required String text,
    required Key key,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        text: text,
        minimumSize: const Size(360, 40),
        key: key,
      );

  factory LoadingButton.stepper({
    required VoidCallback? onPressed,
    required String text,
    required Key key,
    EdgeInsets paddingAroundChild = EdgeInsets.zero,
    Color? outlineColor,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        text: text,
        key: key,
        outlineColor: outlineColor,
        paddingAroundChild: paddingAroundChild,
      );

  factory LoadingButton.icon({
    required VoidCallback? onPressed,
    required Widget icon,
    required Key key,
    String label = '',
    Size minimumSize = const Size(50, 50),
    Color? outlineColor,
    TextStyle? textStyle,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        minimumSize: minimumSize,
        outlineColor: outlineColor,
        textStyle: textStyle,
        key: key,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(
              width: label.isNotEmpty ? 10.0 : 0.0,
            ),
            Text(
              label,
              style: textStyle,
            ),
          ],
        ),
      );
  final Size minimumSize;
  final double minWidth;
  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final Color? outlineColor;
  final EdgeInsets paddingAroundChild;
  final double borderWidth;
  final double circularBorderRadius;
  final TextStyle? textStyle;

  @override
  LoadingButtonState createState() => LoadingButtonState();
}

class LoadingButtonState extends State<LoadingButton>
    with TickerProviderStateMixin {
  double? loaderWidth;

  late Animation<double> _animation;
  late AnimationController _animationController;
  ButtonState btnState = ButtonState.idle;

  final GlobalKey<MyOutlinedButtonState> _outlineButtonKey = GlobalKey();
  double _minWidth = 0;

  double get minWidth => _minWidth;

  set minWidth(double w) {
    if (widget.minWidth == 0) {
      _minWidth = w;
    } else {
      _minWidth = widget.minWidth;
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCirc,
        reverseCurve: Curves.easeInOutCirc,
      ),
    );

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          btnState = ButtonState.idle;
        });
      }
    });

    minWidth = widget.minimumSize.height;
    loaderWidth = widget.minimumSize.height;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return buttonBody();
      },
    );
  }

  Widget buttonBody() {
    return MyOutlinedButton(
      textStyle: widget.textStyle,
      borderWidth: widget.borderWidth,
      outlineColor: widget.outlineColor,
      minimumSize: Size(
        lerpWidth(widget.minimumSize.width, minWidth, _animation.value)!,
        widget.minimumSize.height,
      ),
      onPressed: btnState == ButtonState.idle ? widget.onPressed : null,
      key: _outlineButtonKey,
      circularBorderRadius: lerpDouble(
        widget.circularBorderRadius,
        widget.minimumSize.height / 2,
        _animation.value,
      ),
      padding: widget.paddingAroundChild,
      child: btnState == ButtonState.idle
          ? widget.child ?? Text(widget.text!)
          : const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.znnColor),
              ),
            ),
    );
  }

  void animateForward() {
    if (btnState == ButtonState.idle) {
      setState(() {
        btnState = ButtonState.busy;
      });
      _animationController.forward();
    }
  }

  void animateReverse() {
    if (btnState == ButtonState.busy) {
      _animationController.reverse();
    }
  }

  double? lerpWidth(double a, double b, double t) {
    if (a == 0.0 || b == 0.0) {
      return null;
    } else {
      return a + (b - a) * t;
    }
  }
}
