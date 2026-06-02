part of 'undelegate_bloc.dart';

/// Base class for all undelegate states.
sealed class UndelegateState extends Equatable {
  /// Creates a new [UndelegateState].
  const UndelegateState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before any undelegation action starts.
final class UndelegateInitial extends UndelegateState {
  /// Creates a new [UndelegateInitial] state.
  const UndelegateInitial();
}

/// Failure state emitted when undelegation fails.
final class UndelegateFailure extends UndelegateState {
  /// Creates a new [UndelegateFailure] state.
  const UndelegateFailure({required this.exception});

  /// The error that caused the undelegation operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when undelegation is completed.
final class UndelegateDone extends UndelegateState {
  /// Creates a new [UndelegateDone] state.
  const UndelegateDone();
}

/// Loading state emitted while undelegation is in progress.
final class UndelegateLoading extends UndelegateState {
  /// Creates a new [UndelegateLoading] state.
  const UndelegateLoading();
}
