import 'package:flutter/material.dart';

/// A button that, initially, shows a refresh icon but re-builds to show a
/// loading indicator to show to the user that an async operation is being done
///
/// Future not fully implemented
class RefreshButton extends StatelessWidget {
  /// Constructs a new instance.
  const RefreshButton({
    required this._onPressed,
    super.key,
  });

  final VoidCallback _onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO(maznnwell): implement re-building via a listener
    return _Initial(
      onPressed: _onPressed,
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      icon: const Icon(Icons.refresh),
      onPressed: onPressed,
    );
  }
}
