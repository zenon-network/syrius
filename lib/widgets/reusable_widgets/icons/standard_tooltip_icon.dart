import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Compact icon button that displays a hover [tooltipMessage].
class StandardTooltipIcon extends StatelessWidget {
  /// Creates a [StandardTooltipIcon].
  const StandardTooltipIcon(
    this.tooltipMessage,
    this.iconData, {
    this.iconColor = AppColors.znnColor,
    super.key,
  });

  /// Message shown in the icon's tooltip.
  final String tooltipMessage;

  /// Color of the rendered icon.
  final Color iconColor;

  /// Icon glyph displayed by the button.
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      hoverColor: Colors.transparent,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      iconSize: 15,
      icon: Icon(
        iconData,
        color: iconColor,
      ),
      onPressed: () {},
      tooltip: tooltipMessage,
    );
  }
}
