part of 'p2p_swap_bloc.dart';

/// Base class for single-swap events.
sealed class P2pSwapEvent extends Equatable {
  /// Creates a [P2pSwapEvent].
  const P2pSwapEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests the current swap and starts periodic refreshes.
final class P2pSwapRequested extends P2pSwapEvent {
  /// Creates a [P2pSwapRequested] event.
  const P2pSwapRequested();
}

final class _P2pSwapRefreshRequested extends P2pSwapEvent {
  const _P2pSwapRefreshRequested();
}
