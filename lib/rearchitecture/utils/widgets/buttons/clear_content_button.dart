import 'package:flutter/material.dart';

/// A simple button that helps clear content inside a [TextField] or
/// [TextFormField]
class ClearContentButton extends IconButton {
  ClearContentButton({
    required TextEditingController controller,
    super.key,
  }) : super(
    onPressed: controller.clear,
    icon: const Icon(
      Icons.clear,
    ),
  );
}
