part of 'complete_swap_bloc.dart';

/// Base class for complete-swap events.
sealed class CompleteSwapEvent extends Equatable {
  /// Creates a [CompleteSwapEvent].
  const CompleteSwapEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests completion of an HTLC swap.
final class CompleteSwapRequested extends CompleteSwapEvent {
  /// Creates a [CompleteSwapRequested] event.
  const CompleteSwapRequested({required this.swap});

  /// Swap whose counterparty deposit should be unlocked.
  final HtlcSwap swap;

  @override
  List<Object> get props => <Object>[swap];
}
