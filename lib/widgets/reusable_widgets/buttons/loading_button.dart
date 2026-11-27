import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Visual state of a [LoadingButton].
enum ButtonState {
  /// The button is actively showing a loading indicator.
  busy,

  /// The button is idle and ready for interaction.
  idle,
}

/// Outlined button that smoothly animates into a circular progress indicator.
class LoadingButton extends StatefulWidget {
  /// Creates a [LoadingButton] with either [text] or [child].
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
    this.circularBorderRadius = 16.0,
    this.textStyle,
  }) : assert(
         text != null || child != null,
         'Either text or child must be provided.',
       ),
       super(key: key);

  /// Creates a [LoadingButton] with an icon for infinite-scroll tables.
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
        textStyle: textStyle,
        outlineColor: outlineColor,
        icon: icon,
      );

  /// Creates a compact [LoadingButton] for infinite-scroll tables.
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

  /// Creates a [LoadingButton] styled for settings actions.
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

  /// Creates a [LoadingButton] sized for onboarding screens.
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

  /// Creates a [LoadingButton] styled for stepper actions.
  factory LoadingButton.stepper({
    required VoidCallback? onPressed,
    required String text,
    required Key key,
    EdgeInsets paddingAroundChild = EdgeInsets.zero,
    Color? outlineColor,
    Color? textColor,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        text: text,
        key: key,
        outlineColor: outlineColor,
        paddingAroundChild: paddingAroundChild,
        textStyle: TextStyle(color: textColor),
      );

  /// Creates a [LoadingButton] displaying an [icon] and optional [label].
  factory LoadingButton.icon({
    required VoidCallback? onPressed,
    required Widget icon,
    required Key key,
    String label = '',
    Color? outlineColor,
    TextStyle? textStyle,
  }) =>
      LoadingButton(
        onPressed: onPressed,
        outlineColor: outlineColor,
        textStyle: textStyle,
        key: key,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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

  /// Minimum size of the button in its idle state.
  final Size minimumSize;

  /// Target collapsed width during the loading animation.
  final double minWidth;

  /// Callback invoked when the button is pressed while idle.
  final VoidCallback? onPressed;

  /// Button label text used when [child] is omitted.
  final String? text;

  /// Custom child widget rendered inside the button when idle.
  final Widget? child;

  /// Optional custom border color for the outlined button.
  final Color? outlineColor;

  /// Padding applied around the button child.
  final EdgeInsets paddingAroundChild;

  /// Width of the button outline border.
  final double borderWidth;

  /// Corner radius of the button when idle.
  final double circularBorderRadius;

  /// Optional text style applied to the button label.
  final TextStyle? textStyle;

  @override
  LoadingButtonState createState() => LoadingButtonState();
}

/// State object for [LoadingButton] exposing animation controls.
class LoadingButtonState extends State<LoadingButton>
    with TickerProviderStateMixin {
  /// Width of the circular loader when busy.
  double? loaderWidth;

  late Animation<double> _animation;
  late AnimationController _animationController;

  /// Current [ButtonState] of the button.
  ButtonState btnState = ButtonState.idle;

  final GlobalKey<MyOutlinedButtonState> _outlineButtonKey = GlobalKey();
  double _minWidth = 0;

  /// Effective minimum width used when collapsed into a loader.
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

    _animation.addStatusListener((AnimationStatus status) {
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
      builder: (BuildContext context, Widget? child) {
        return buttonBody();
      },
    );
  }

  /// Builds the underlying [MyOutlinedButton] for the current animation frame.
  Widget buttonBody() {
    final Color? textColor = widget.textStyle?.color;

    return MyOutlinedButton(
      textColor: textColor,
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
          : SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.znnColor),
              ),
            ),
    );
  }

  /// Transitions the button from [ButtonState.idle] to [ButtonState.busy].
  void animateForward() {
    if (btnState == ButtonState.idle) {
      setState(() {
        btnState = ButtonState.busy;
      });
      _animationController.forward();
    }
  }

  /// Reverses the animation back toward [ButtonState.idle].
  void animateReverse() {
    if (btnState == ButtonState.busy) {
      _animationController.reverse();
    }
  }

  /// Linearly interpolates between widths [a] and [b] at factor [t].
  double? lerpWidth(double a, double b, double t) {
    if (a == 0.0 || b == 0.0) {
      return null;
    } else {
      return a + (b - a) * t;
    }
  }
}
