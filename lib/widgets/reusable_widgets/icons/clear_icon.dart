import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class ClearIcon extends RawMaterialButton {
  ClearIcon({
    required VoidCallback super.onPressed, required BuildContext context, super.key,
  }) : super(
          shape: const CircleBorder(),
          child: Icon(
            SimpleLineIcons.close,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        );
}
