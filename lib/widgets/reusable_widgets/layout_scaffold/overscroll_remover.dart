import 'package:flutter/material.dart';

/// [ScrollBehavior] that suppresses the platform overscroll glow indicator.
class RemoveOverscrollEffect extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details,) {
    return child;
  }
}
