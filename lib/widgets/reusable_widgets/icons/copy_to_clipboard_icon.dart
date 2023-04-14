import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';

class CopyToClipboardIcon extends StatelessWidget {
  final String? textToBeCopied;
  final Color iconColor;
  final Color? hoverColor;
  final MaterialTapTargetSize materialTapTargetSize;

  const CopyToClipboardIcon(
    this.textToBeCopied, {
    this.iconColor = AppColors.znnColor,
    this.hoverColor,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      materialTapTargetSize: materialTapTargetSize,
      hoverColor: hoverColor,
      constraints: const BoxConstraints.tightForFinite(),
      padding: const EdgeInsets.all(8.0),
      shape: const CircleBorder(),
      onPressed: () => ClipboardUtils.copyToClipboard(textToBeCopied!, context),
      child: Icon(
        Icons.content_copy,
        color: iconColor,
        size: 15.0,
      ),
    );
  }
}
