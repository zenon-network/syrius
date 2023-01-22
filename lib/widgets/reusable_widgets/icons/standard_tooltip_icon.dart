import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class StandardTooltipIcon extends StatelessWidget {
  final String tooltipMessage;
  final Color iconColor;
  final IconData iconData;

  const StandardTooltipIcon(
    this.tooltipMessage,
    this.iconData, {
    this.iconColor = AppColors.znnColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      hoverColor: Colors.transparent,
      padding: const EdgeInsets.all(4.0),
      constraints: const BoxConstraints(),
      iconSize: 15.0,
      icon: Icon(
        iconData,
        color: iconColor,
      ),
      onPressed: () {},
      tooltip: tooltipMessage,
    );
  }
}
