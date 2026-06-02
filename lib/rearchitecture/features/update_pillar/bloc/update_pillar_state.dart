part of 'update_pillar_bloc.dart';

/// Base class for all update pillar states.
sealed class UpdatePillarState extends Equatable {
  /// Creates a new [UpdatePillarState].
  const UpdatePillarState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before any pillar update action starts.
final class UpdatePillarInitial extends UpdatePillarState {
  /// Creates a new [UpdatePillarInitial] state.
  const UpdatePillarInitial();
}

/// Failure state emitted when the pillar update fails.
final class UpdatePillarFailure extends UpdatePillarState {
  /// Creates a new [UpdatePillarFailure] state.
  const UpdatePillarFailure({required this.exception});

  /// The error that caused the update operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when the pillar update is completed.
final class UpdatePillarDone extends UpdatePillarState {
  /// Creates a new [UpdatePillarDone] state.
  const UpdatePillarDone();
}

/// Loading state emitted while the pillar update is in progress.
final class UpdatePillarLoading extends UpdatePillarState {
  /// Creates a new [UpdatePillarLoading] state.
  const UpdatePillarLoading();
}
