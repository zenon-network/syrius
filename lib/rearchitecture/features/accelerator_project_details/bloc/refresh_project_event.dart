part of 'refresh_project_bloc.dart';

/// Base event for [RefreshProjectBloc].
sealed class RefreshProjectEvent extends Equatable {
  /// Creates a [RefreshProjectEvent].
  const RefreshProjectEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests reloading an Accelerator project by its [projectId].
final class RefreshProjectRequested extends RefreshProjectEvent {
  /// Creates a [RefreshProjectRequested] event.
  const RefreshProjectRequested({required this.projectId});

  /// Identifier of the project to fetch.
  final Hash projectId;

  @override
  List<Object?> get props => <Object?>[projectId];
}
