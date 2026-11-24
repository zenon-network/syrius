part of 'complete_swap_bloc.dart';

/// Base class for complete-swap states.
sealed class CompleteSwapState extends Equatable {
  /// Creates a [CompleteSwapState].
  const CompleteSwapState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before completion is requested.
final class CompleteSwapInitial extends CompleteSwapState {
  /// Creates a [CompleteSwapInitial] state.
  const CompleteSwapInitial();
}

/// Loading state while the unlock transaction is being submitted.
final class CompleteSwapLoading extends CompleteSwapState {
  /// Creates a [CompleteSwapLoading] state.
  const CompleteSwapLoading();
}

/// Success state emitted after the completed swap is stored.
final class CompleteSwapDone extends CompleteSwapState {
  /// Creates a [CompleteSwapDone] state.
  const CompleteSwapDone({required this.block, required this.swap});

  /// The submitted unlock block.
  final AccountBlockTemplate block;

  /// Completed HTLC swap.
  final HtlcSwap swap;

  @override
  List<Object> get props => <Object>[block, swap];
}

/// Failure state emitted when the swap cannot be completed.
final class CompleteSwapFailure extends CompleteSwapState {
  /// Creates a [CompleteSwapFailure] state.
  const CompleteSwapFailure({required this.exception});

  /// Error that prevented the swap from being completed.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}
