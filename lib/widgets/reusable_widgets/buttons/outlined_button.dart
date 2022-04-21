import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

class MyOutlinedButton extends StatefulWidget {
  final String? text;
  final TextStyle? textStyle;
  final Color? outlineColor;
  final VoidCallback? onPressed;
  final Size? minimumSize;
  final Widget? child;
  final double borderWidth;
  final double? circularBorderRadius;
  final Color? textColor;
  final EdgeInsets? padding;

  const MyOutlinedButton({
    this.text,
    this.textStyle,
    this.outlineColor,
    this.minimumSize,
    this.child,
    this.borderWidth = kDefaultBorderOutlineWidth,
    this.circularBorderRadius,
    this.textColor,
    this.padding,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

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

  @override
  MyOutlinedButtonState createState() => MyOutlinedButtonState();
}

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
      child: _showLoading
          ? const SyriusLoadingWidget(
              size: 25.0,
            )
          : widget.text != null
              ? Text(
                  widget.text!,
                )
              : widget.child!,
      style: OutlinedButton.styleFrom(
        primary: widget.textColor,
        padding: widget.padding,
        minimumSize: widget.minimumSize,
        textStyle: widget.textStyle,
        shape: widget.circularBorderRadius != null
            ? RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(widget.circularBorderRadius!),
              )
            : null,
      ).copyWith(
        side: MaterialStateProperty.resolveWith<BorderSide?>(
          (states) {
            if (states.contains(MaterialState.disabled)) {
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
    );
  }

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
    Color? outlineColor,
    required VoidCallback? onPressed,
    Key? key,
  }) : super(
          onPressed: onPressed,
          outlineColor: outlineColor,
          key: key,
          child: _MyOutlinedButtonWithIconChild(
            label: label,
            icon: icon,
          ),
        );
}

class _MyOutlinedButtonWithIconChild extends StatelessWidget {
  final String label;
  final Widget icon;

  const _MyOutlinedButtonWithIconChild({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(
          width: 15.0,
        ),
        Text(label),
      ],
    );
  }
}
