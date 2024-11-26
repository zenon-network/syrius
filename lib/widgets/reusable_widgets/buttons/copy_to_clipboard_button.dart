import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';

class CopyToClipboardButton extends StatefulWidget {
  const CopyToClipboardButton(
    this.textToBeCopied, {
    super.key,
  });

  final String textToBeCopied;

  @override
  State<CopyToClipboardButton> createState() => _CopyToClipboardIcon();
}

class _CopyToClipboardIcon extends State<CopyToClipboardButton> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    const Widget firstChild = Icon(
      Icons.content_copy,
      color: AppColors.znnColor,
    );

    const Widget secondChild = Icon(
      Icons.check,
      color: AppColors.znnColor,
    );

    return IconButton(
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
        ClipboardUtils.copyToClipboard(widget.textToBeCopied, context);
      },
      icon: AnimatedCrossFade(
        duration: const Duration(milliseconds: 100),
        firstChild: firstChild,
        secondChild: secondChild,
        crossFadeState:
            _isCopied ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      ),
    );
  }
}
