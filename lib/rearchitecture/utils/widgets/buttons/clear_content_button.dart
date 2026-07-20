import 'package:flutter/material.dart';

/// A simple button that helps clear content inside a [TextField] or
/// [TextFormField]
class ClearContentButton extends StatelessWidget {
  /// Creates a button that clears [_controller].
  const ClearContentButton({required this._controller, super.key});

  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (_, TextEditingValue value, _) {
        final bool isActive = value.text.isNotEmpty;

        return IconButton(
          onPressed: isActive ? _controller.clear : null,
          icon: const Icon(Icons.clear),
        );
      },
    );
  }
}
