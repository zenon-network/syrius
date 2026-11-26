import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bridges a BLoC or Cubit's state stream into a [ValueListenable<bool>] for
/// `RefreshButton` / `NewCardScaffold.isRefreshLoading`.
///
/// Keeps a stable [ValueNotifier<bool>] instance across rebuilds and manages
/// stream subscriptions cleanly on bloc swap and widget disposal.
class BlocRefreshLoadingBuilder<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  /// Creates a [BlocRefreshLoadingBuilder].
  const BlocRefreshLoadingBuilder({
    required this._isLoading,
    required this._builder,
    this._bloc,
    super.key,
  });

  final B? _bloc;
  final bool Function(S state) _isLoading;
  final Widget Function(
    BuildContext context,
    ValueListenable<bool> isRefreshLoading,
  )
  _builder;

  @override
  State<BlocRefreshLoadingBuilder<B, S>> createState() =>
      _BlocRefreshLoadingBuilderState<B, S>();
}

class _BlocRefreshLoadingBuilderState<B extends StateStreamable<S>, S>
    extends State<BlocRefreshLoadingBuilder<B, S>> {
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  B? _currentBloc;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBloc();
  }

  @override
  void didUpdateWidget(covariant BlocRefreshLoadingBuilder<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBloc();
  }

  void _syncBloc() {
    final B targetBloc = widget._bloc ?? context.read<B>();
    if (!identical(_currentBloc, targetBloc)) {
      unawaited(_subscription?.cancel());
      _currentBloc = targetBloc;
      _isLoadingNotifier.value = widget._isLoading(targetBloc.state);
      _subscription = targetBloc.stream.listen((S state) {
        _isLoadingNotifier.value = widget._isLoading(state);
      });
    } else {
      _isLoadingNotifier.value = widget._isLoading(targetBloc.state);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._bloc == null) {
      // Subscribe only to provider instance swaps (not state emissions) so a
      // reused child resubscribes when BlocProvider.value replaces the bloc.
      context.select<B, bool>((B bloc) => identical(_currentBloc, bloc));
    }
    return widget._builder(context, _isLoadingNotifier);
  }
}
