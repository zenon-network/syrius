import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Circular icon button displaying a close/clear icon.
class ClearIcon extends RawMaterialButton {
  /// Creates a [ClearIcon].
  ClearIcon({
    required VoidCallback super.onPressed,
    required BuildContext context,
    super.key,
  }) : super(
          shape: const CircleBorder(),
          child: Icon(
            SimpleLineIcons.close,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        );
}
