part of 'refresh_project_bloc.dart';

/// Base state for [RefreshProjectBloc].
sealed class RefreshProjectState extends Equatable {
  /// Creates a [RefreshProjectState].
  const RefreshProjectState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before the project details have been loaded.
final class RefreshProjectInitial extends RefreshProjectState {
  /// Creates a [RefreshProjectInitial] state.
  const RefreshProjectInitial();
}

/// State emitted while fetching the latest project details from the node.
final class RefreshProjectLoading extends RefreshProjectState {
  /// Creates a [RefreshProjectLoading] state.
  const RefreshProjectLoading();
}

/// State emitted once the latest project details have been loaded.
final class RefreshProjectPopulated extends RefreshProjectState {
  /// Creates a [RefreshProjectPopulated] state.
  const RefreshProjectPopulated({required this.project});

  /// Loaded Accelerator project.
  final Project project;

  @override
  List<Object?> get props => <Object?>[project];
}

/// State emitted when fetching the project fails.
final class RefreshProjectFailure extends RefreshProjectState {
  /// Creates a [RefreshProjectFailure] state.
  const RefreshProjectFailure({required this.exception});

  /// Failure describing why loading the project did not succeed.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
