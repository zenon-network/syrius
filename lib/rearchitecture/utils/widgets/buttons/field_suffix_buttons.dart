import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class FieldSuffixButtons extends Row {
  FieldSuffixButtons({required TextEditingController controller, super.key})
    : super(
        mainAxisSize: .min,
        children: <Widget>[
          PasteContentButton(controller: controller),
          ClearContentButton(controller: controller),
        ],
      );
}
