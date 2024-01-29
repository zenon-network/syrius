import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class MaterialIconButton extends StatelessWidget {
  final Color iconColor;
  final Color? hoverColor;
  final double padding;
  final MaterialTapTargetSize materialTapTargetSize;
  final VoidCallback onPressed;
  final IconData iconData;

  const MaterialIconButton({
    required this.onPressed,
    required this.iconData,
    this.iconColor = AppColors.znnColor,
    this.hoverColor,
    this.padding = 8.0,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    Key? key,
  }) : super(key: key);

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
        size: 15.0,
      ),
    );
  }
}
