import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';

/// Icon button that copies text to the clipboard and briefly shows a checkmark.
class CopyToClipboardButton extends StatefulWidget {
  /// Creates a [CopyToClipboardButton].
  const CopyToClipboardButton(
    this._textToBeCopied, {
    this.iconSize,
    super.key,
  });

  final String _textToBeCopied;

  /// Optional override for the copy and check icon size.
  final double? iconSize;

  @override
  State<CopyToClipboardButton> createState() => _CopyToClipboardIcon();
}

class _CopyToClipboardIcon extends State<CopyToClipboardButton> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final double iconSize = widget.iconSize ?? 24;

    final Widget firstChild = Icon(
      Icons.content_copy,
      color: AppColors.znnColor,
      size: iconSize,
    );

    final Widget secondChild = Icon(
      Icons.check,
      color: AppColors.znnColor,
      size: iconSize,
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
        ClipboardUtils.copyToClipboard(widget._textToBeCopied, context);
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
