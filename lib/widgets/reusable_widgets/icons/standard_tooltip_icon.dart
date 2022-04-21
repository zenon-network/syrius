import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class StandardTooltipIcon extends StatelessWidget {
  final String tooltipMessage;
  final Color iconColor;

  const StandardTooltipIcon(
    this.tooltipMessage, {
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
        Icons.help_sharp,
        color: iconColor,
      ),
      onPressed: () {},
      tooltip: tooltipMessage,
    );
  }
}
