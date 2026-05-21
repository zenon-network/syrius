import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// A simple button that helps paste content inside a [TextField] or
/// [TextFormField]
class PasteContentButton extends IconButton {
  PasteContentButton({
    required TextEditingController controller,
    super.key,
  }) : super(
          onPressed: () {
            ClipboardUtils.pasteToClipboard(callback: (String value) {
              controller.text = value;
            });
          },
          icon: const Icon(
            Icons.content_paste,
          ),
        );
}
