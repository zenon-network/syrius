import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

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
    const bool isLoading = false;
    // TODO(maznnwell): implement re-building via a listener
    return isLoading ? const _Loading() : _Initial(onPressed: _onPressed,);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const IconButton(
      onPressed: null,
      icon: SyriusLoadingWidget(
        padding: 0,
        strokeWidth: 2,
        size: 20,
      ),
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
      icon: const Icon(Icons.refresh),
      onPressed: onPressed,
    );
  }
}


