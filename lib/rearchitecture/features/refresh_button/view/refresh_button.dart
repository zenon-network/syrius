import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A button that shows a refresh icon and rebuilds to show a loading indicator
/// while an async refresh operation is in progress.
class RefreshButton extends StatelessWidget {
  /// Constructs a new instance.
  const RefreshButton({
    required this._onPressed,
    this._isLoadingListenable,
    super.key,
  });

  final VoidCallback _onPressed;
  final ValueListenable<bool>? _isLoadingListenable;

  @override
  Widget build(BuildContext context) {
    final ValueListenable<bool>? isLoadingListenable = _isLoadingListenable;
    if (isLoadingListenable == null) {
      return _Initial(onPressed: _onPressed);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingListenable,
      builder: (_, bool isLoading, _) =>
          isLoading ? const _Loading() : _Initial(onPressed: _onPressed),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const IconButton(
      onPressed: null,
      icon: SyriusLoadingWidget(padding: 0, strokeWidth: 2, size: 20),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this._onPressed});

  final VoidCallback _onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      icon: const Icon(Icons.refresh),
      onPressed: _onPressed,
    );
  }
}
