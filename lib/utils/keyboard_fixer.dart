import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/*
Class that is used to fix the SHIFT right bug: after pressing and releasing
the key, it stays locked, as if it was still being pressed
 */
class KeyboardFixer extends StatefulWidget {
  const KeyboardFixer({required this.child, Key? key}) : super(key: key);
  final Widget child;

  @override
  State<StatefulWidget> createState() => _KeyboardFixerState();
}

class _KeyboardFixerState extends State<KeyboardFixer> {
  final List<PhysicalKeyboardKey> _keysToBeIgnored = [
    PhysicalKeyboardKey.shiftRight,
    PhysicalKeyboardKey.controlLeft,
  ];

  final FocusNode focus = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focus,
      onKey: (_, RawKeyEvent event) {
        return _keysToBeIgnored.contains(event.physicalKey)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
