import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class FieldSuffixButtons extends Row {
  FieldSuffixButtons({super.key, required TextEditingController controller})
    : super(
        mainAxisSize: .min,
        children: [
          PasteContentButton(controller: controller),
          ClearContentButton(controller: controller),
        ],
      );
}
