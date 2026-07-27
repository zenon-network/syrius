part of 'cancel_stake_bloc.dart';

/// Base class for all cancel stake events.
sealed class CancelStakeEvent extends Equatable {
  /// Creates a new [CancelStakeEvent].
  const CancelStakeEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests cancellation of an expired stake.
final class CancelStakeRequested extends CancelStakeEvent {
  /// Creates a new [CancelStakeRequested] event.
  const CancelStakeRequested({required this.stakeHash});

  /// Hash of the stake entry that should be cancelled.
  final Hash stakeHash;

  @override
  List<Object> get props => <Object>[stakeHash];
}
