part of 'reclaim_deposit_bloc.dart';

/// Base class for reclaim-deposit events.
sealed class ReclaimDepositEvent extends Equatable {
  /// Creates a [ReclaimDepositEvent].
  const ReclaimDepositEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests that an expired deposit be reclaimed.
final class ReclaimDepositRequested extends ReclaimDepositEvent {
  /// Creates a [ReclaimDepositRequested] event.
  const ReclaimDepositRequested({required this.depositId});

  /// Identifier of the deposit to reclaim.
  final Hash depositId;

  @override
  List<Object> get props => <Object>[depositId];
}
