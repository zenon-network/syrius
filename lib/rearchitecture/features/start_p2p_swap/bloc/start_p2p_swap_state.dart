part of 'start_p2p_swap_bloc.dart';

/// Base class for start-HTLC-swap states.
sealed class StartP2pSwapState extends Equatable {
  /// Creates a [StartP2pSwapState].
  const StartP2pSwapState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before an HTLC swap is requested.
final class StartP2pSwapInitial extends StartP2pSwapState {
  /// Creates a [StartP2pSwapInitial] state.
  const StartP2pSwapInitial();
}

/// Loading state while the HTLC swap is being created.
final class StartP2pSwapLoading extends StartP2pSwapState {
  /// Creates a [StartP2pSwapLoading] state.
  const StartP2pSwapLoading();
}

/// Success state emitted after the HTLC swap has been stored.
final class StartP2pSwapDone extends StartP2pSwapState {
  /// Creates a [StartP2pSwapDone] state.
  const StartP2pSwapDone({required this.swap});

  /// Newly created outgoing HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when the HTLC swap cannot be started.
final class StartP2pSwapFailure extends StartP2pSwapState {
  /// Creates a [StartP2pSwapFailure] state.
  const StartP2pSwapFailure({required this.exception});

  /// Error that prevented the swap from being started.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
