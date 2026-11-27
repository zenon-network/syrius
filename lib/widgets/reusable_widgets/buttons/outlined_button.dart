import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Custom outlined button with configurable border styling and loading state.
class MyOutlinedButton extends StatefulWidget {
  /// Creates a [MyOutlinedButton].
  const MyOutlinedButton({
    required this.onPressed,
    this.text,
    this.textStyle,
    this.outlineColor,
    this.minimumSize,
    this.child,
    this.borderWidth = kDefaultBorderOutlineWidth,
    this.circularBorderRadius,
    this.textColor,
    this.padding,
    super.key,
  });

  /// Creates a [MyOutlinedButton] containing an [icon] next to a [label].
  factory MyOutlinedButton.icon({
    required VoidCallback? onPressed,
    required String label,
    required Widget icon,
    Color? outlineColor,
    Key? key,
  }) =>
      _MyOutlinedButtonWithIcon(
        onPressed: onPressed,
        label: label,
        icon: icon,
        outlineColor: outlineColor,
        key: key,
      );

  /// Optional label text shown when [child] is omitted.
  final String? text;

  /// Optional text style for the button label.
  final TextStyle? textStyle;

  /// Optional custom color for the button border.
  final Color? outlineColor;

  /// Callback invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional minimum size constraint for the button.
  final Size? minimumSize;

  /// Custom child widget displayed when [text] is `null`.
  final Widget? child;

  /// Thickness of the outline border.
  final double borderWidth;

  /// Optional corner radius for the rounded rectangle border.
  final double? circularBorderRadius;

  /// Optional foreground color applied to the button label.
  final Color? textColor;

  /// Optional padding inside the button.
  final EdgeInsets? padding;

  @override
  MyOutlinedButtonState createState() => MyOutlinedButtonState();
}

/// State object for [MyOutlinedButton].
class MyOutlinedButtonState extends State<MyOutlinedButton> {
  late bool _showLoading;

  @override
  void initState() {
    super.initState();
    _showLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _showLoading ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.textColor,
        padding: widget.padding,
        minimumSize: widget.minimumSize,
        textStyle: widget.textStyle,
        // TODO(syrius): standardize circular border radius.
        shape: widget.circularBorderRadius != null
            ? RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(widget.circularBorderRadius!),
              )
            : null,
      ).copyWith(
        side: WidgetStateProperty.resolveWith<BorderSide?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: AppColors.lightSecondaryContainer,
                width: widget.borderWidth,
              );
            }
            if (widget.outlineColor != null) {
              return BorderSide(
                color: widget.outlineColor!,
                width: widget.borderWidth,
              );
            }
            if (widget.borderWidth != kDefaultBorderOutlineWidth) {
              return BorderSide(
                width: widget.borderWidth,
                color: AppColors.znnColor,
              );
            }
            return null;
          },
        ),
      ),
      child: _showLoading
          ? const SyriusLoadingWidget(
              size: 25,
            )
          : widget.text != null
              ? Text(
                  widget.text!,
                )
              : widget.child!,
    );
  }

  /// Toggles whether the button displays a loading indicator.
  // Preserves the existing public method signature.
  // ignore: avoid_positional_boolean_parameters
  void showLoadingIndicator(bool showLoading) {
    if (_showLoading != showLoading) {
      setState(() {
        _showLoading = showLoading;
      });
    }
  }
}

class _MyOutlinedButtonWithIcon extends MyOutlinedButton {
  _MyOutlinedButtonWithIcon({
    required String label,
    required Widget icon,
    required super.onPressed, super.outlineColor,
    super.key,
  }) : super(
          child: _MyOutlinedButtonWithIconChild(
            label: label,
            icon: icon,
          ),
        );
}

class _MyOutlinedButtonWithIconChild extends StatelessWidget {

  const _MyOutlinedButtonWithIconChild({
    required this.label,
    required this.icon,
  });
  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        icon,
        const SizedBox(
          width: 15,
        ),
        Text(label),
      ],
    );
  }
}
