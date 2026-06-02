part of 'delegation_bloc.dart';

/// Base class for all delegation states.
sealed class DelegationState extends Equatable {
  /// Creates a new [DelegationState].
  const DelegationState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before any delegation action starts.
final class DelegationInitial extends DelegationState {
  /// Creates a new [DelegationInitial] state.
  const DelegationInitial();
}

/// Failure state emitted when delegation fails.
final class DelegationFailure extends DelegationState {
  /// Creates a new [DelegationFailure] state.
  const DelegationFailure({required this._exception});

  final SyriusException _exception;

  /// The error that caused the delegation operation to fail.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}

/// Success state emitted when delegation is completed.
final class DelegationDone extends DelegationState {
  /// Creates a new [DelegationDone] state.
  const DelegationDone();
}

/// Loading state emitted while delegation is in progress.
final class DelegationLoading extends DelegationState {
  /// Creates a new [DelegationLoading] state.
  const DelegationLoading();
}
