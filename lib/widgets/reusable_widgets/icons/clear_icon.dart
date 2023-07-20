import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class ClearIcon extends RawMaterialButton {
  ClearIcon({
    Key? key,
    required VoidCallback onPressed,
    required BuildContext context,
  }) : super(
          key: key,
          onPressed: onPressed,
          shape: const CircleBorder(),
          child: Icon(
            SimpleLineIcons.close,
            color: Theme.of(context).colorScheme.secondary,
            size: 20.0,
          ),
        );
}
