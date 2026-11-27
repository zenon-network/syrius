import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Circular raw material button wrapping a configurable [Icon].
class MaterialIconButton extends StatelessWidget {
  /// Creates a [MaterialIconButton].
  const MaterialIconButton({
    required this.onPressed,
    required this.iconData,
    required this.size,
    this.iconColor = AppColors.znnColor,
    this.hoverColor,
    this.padding = 8.0,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    super.key,
  });

  /// Color of the rendered icon.
  final Color iconColor;

  /// Optional background color shown while hovering over the button.
  final Color? hoverColor;

  /// Uniform padding inside the circular button.
  final double padding;

  /// Tap target sizing policy for the button.
  final MaterialTapTargetSize materialTapTargetSize;

  /// Callback invoked when the button is pressed.
  final VoidCallback onPressed;

  /// Icon glyph displayed inside the button.
  final IconData iconData;

  /// Size of the rendered icon in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      materialTapTargetSize: materialTapTargetSize,
      hoverColor: hoverColor,
      constraints: const BoxConstraints.tightForFinite(),
      padding: EdgeInsets.all(padding),
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: Icon(
        iconData,
        color: iconColor,
        size: size,
      ),
    );
  }
}
