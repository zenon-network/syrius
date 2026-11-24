part of 'p2p_swaps_cubit.dart';

/// Base class for P2P-swaps-list states.
sealed class P2pSwapsState extends Equatable {
  /// Creates a [P2pSwapsState].
  const P2pSwapsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loading state while P2P swaps are initially being observed.
final class P2pSwapsLoading extends P2pSwapsState {
  /// Creates a [P2pSwapsLoading] state.
  const P2pSwapsLoading();
}

/// Populated state containing the latest persisted P2P swaps.
final class P2pSwapsPopulated extends P2pSwapsState {
  /// Creates a [P2pSwapsPopulated] state.
  const P2pSwapsPopulated({required this.swaps});

  /// The latest persisted P2P swaps, ordered newest first.
  final List<P2pSwap> swaps;

  @override
  List<Object?> get props => <Object?>[swaps];
}

/// Failure state emitted when P2P swaps cannot be observed.
final class P2pSwapsFailure extends P2pSwapsState {
  /// Creates a [P2pSwapsFailure] state.
  const P2pSwapsFailure({required this.exception});

  /// Error that prevented the P2P swaps from being observed.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
