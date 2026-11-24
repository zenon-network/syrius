part of 'p2p_swap_bloc.dart';

/// Base class for the single-swap bloc states.
sealed class P2pSwapBlocState extends Equatable {
  /// Creates a [P2pSwapBlocState].
  const P2pSwapBlocState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before the swap has been requested.
final class P2pSwapInitial extends P2pSwapBlocState {
  /// Creates a [P2pSwapInitial] state.
  const P2pSwapInitial();
}

/// Loading state while the swap is being fetched.
final class P2pSwapLoading extends P2pSwapBlocState {
  /// Creates a [P2pSwapLoading] state.
  const P2pSwapLoading();
}

/// Populated state containing the latest swap.
final class P2pSwapPopulated extends P2pSwapBlocState {
  /// Creates a [P2pSwapPopulated] state.
  const P2pSwapPopulated({required this.swap});

  /// The latest persisted HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when the swap cannot be fetched.
final class P2pSwapFailure extends P2pSwapBlocState {
  /// Creates a [P2pSwapFailure] state.
  const P2pSwapFailure({required this.exception});

  /// Error that prevented the swap from being fetched.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
