import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// A row of suffix buttons for pasting and clearing text field content.
class FieldSuffixButtons extends Row {
  /// Creates suffix buttons bound to [controller].
  FieldSuffixButtons({required TextEditingController controller, super.key})
    : super(
        mainAxisSize: .min,
        children: <Widget>[
          PasteContentButton(controller: controller),
          ClearContentButton(controller: controller),
        ],
      );
}
