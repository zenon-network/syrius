import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// A simple button that helps paste content inside a [TextField] or
/// [TextFormField]
class ContentPasteButton extends IconButton {
  ContentPasteButton({
    required TextEditingController controller,
    super.key,
  }) : super(
          onPressed: () {
            ClipboardUtils.pasteToClipboard(callback: (String value) {
              controller.text = value;
            });
          },
    // TODO: show clear icon when controller is not empty
          icon: const Icon(
            Icons.content_paste,
          ),
        );
}
