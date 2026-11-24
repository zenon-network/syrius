part of 'join_p2p_swap_bloc.dart';

/// Base class for join-native-swap states.
sealed class JoinP2pSwapState extends Equatable {
  /// Creates a [JoinP2pSwapState].
  const JoinP2pSwapState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before an HTLC swap is joined.
final class JoinP2pSwapInitial extends JoinP2pSwapState {
  /// Creates a [JoinP2pSwapInitial] state.
  const JoinP2pSwapInitial();
}

/// Loading state while the counter HTLC is being created.
final class JoinP2pSwapLoading extends JoinP2pSwapState {
  /// Creates a [JoinP2pSwapLoading] state.
  const JoinP2pSwapLoading();
}

/// Success state emitted after the incoming swap has been stored.
final class JoinP2pSwapDone extends JoinP2pSwapState {
  /// Creates a [JoinP2pSwapDone] state.
  const JoinP2pSwapDone({required this.swap});

  /// Newly created incoming HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object?> get props => <Object?>[swap];
}

/// Failure state emitted when the HTLC swap cannot be joined.
final class JoinP2pSwapFailure extends JoinP2pSwapState {
  /// Creates a [JoinP2pSwapFailure] state.
  const JoinP2pSwapFailure({required this.exception});

  /// Error that prevented the swap from being joined.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
