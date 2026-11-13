import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';

/// Paste button symmetric to the copy icon: on tap it reads the
/// clipboard and hands the text to [onValue]. Callers typically set a
/// TextEditingController's text inside setState from [onValue], because
/// programmatic text changes do not fire InputField onChanged callbacks.
class PasteFromClipboardIcon extends StatelessWidget {
  final void Function(String value) onValue;
  final Color iconColor;
  final Color? hoverColor;
  final MaterialTapTargetSize materialTapTargetSize;
  final EdgeInsets padding;

  const PasteFromClipboardIcon({
    required this.onValue,
    this.iconColor = AppColors.znnColor,
    this.hoverColor,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    this.padding = const EdgeInsets.all(8.0),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      materialTapTargetSize: materialTapTargetSize,
      hoverColor: hoverColor,
      constraints: const BoxConstraints.tightForFinite(),
      padding: padding,
      shape: const CircleBorder(),
      onPressed: () {
        ClipboardUtils.pasteToClipboard(context, onValue);
      },
      child: Icon(Icons.content_paste, color: iconColor, size: 15.0),
    );
  }
}
