part of 'cancel_stake_bloc.dart';

/// Base class for all cancel stake states.
sealed class CancelStakeState extends Equatable {
  /// Creates a new [CancelStakeState].
  const CancelStakeState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before stake cancellation starts.
final class CancelStakeInitial extends CancelStakeState {
  /// Creates a new [CancelStakeInitial] state.
  const CancelStakeInitial();
}

/// Failure state emitted when stake cancellation fails.
final class CancelStakeFailure extends CancelStakeState {
  /// Creates a new [CancelStakeFailure] state.
  const CancelStakeFailure({required this.exception});

  /// The error that caused the cancellation operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when stake cancellation completes.
final class CancelStakeDone extends CancelStakeState {
  /// Creates a new [CancelStakeDone] state.
  const CancelStakeDone();
}

/// Loading state emitted while stake cancellation is in progress.
final class CancelStakeLoading extends CancelStakeState {
  /// Creates a new [CancelStakeLoading] state.
  const CancelStakeLoading();
}
