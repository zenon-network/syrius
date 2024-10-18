import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';

class CopyToClipboardIcon extends StatefulWidget {

  const CopyToClipboardIcon(
    this.textToBeCopied, {
    this.iconColor = AppColors.znnColor,
    this.hoverColor,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    this.icon = Icons.content_copy,
    this.padding = const EdgeInsets.all(8),
    super.key,
  });
  final String? textToBeCopied;
  final Color iconColor;
  final Color? hoverColor;
  final MaterialTapTargetSize materialTapTargetSize;
  final IconData icon;
  final EdgeInsets padding;

  @override
  State<CopyToClipboardIcon> createState() => _CopyToClipboardIcon();
}

class _CopyToClipboardIcon extends State<CopyToClipboardIcon> {
  final _iconSize = 15.0;
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      materialTapTargetSize: widget.materialTapTargetSize,
      hoverColor: widget.hoverColor,
      constraints: const BoxConstraints.tightForFinite(),
      padding: widget.padding,
      shape: const CircleBorder(),
      onPressed: () {
        if (!_isCopied) {
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isCopied = false;
              });
            }
          });
          setState(() {
            _isCopied = true;
          });
        }
        ClipboardUtils.copyToClipboard(widget.textToBeCopied!, context);
      },
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 100),
        firstChild: Icon(widget.icon, color: widget.iconColor, size: _iconSize),
        secondChild:
            Icon(Icons.check, color: AppColors.znnColor, size: _iconSize),
        crossFadeState:
            _isCopied ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      ),
    );
  }
}
