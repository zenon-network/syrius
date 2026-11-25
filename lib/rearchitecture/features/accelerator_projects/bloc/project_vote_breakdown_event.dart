part of 'project_vote_breakdown_bloc.dart';

/// Base event for [ProjectVoteBreakdownBloc].
sealed class ProjectVoteBreakdownEvent extends Equatable {
  /// Creates a [ProjectVoteBreakdownEvent].
  const ProjectVoteBreakdownEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests the vote breakdown and optional Pillar vote for [projectId].
final class ProjectVoteBreakdownRequested extends ProjectVoteBreakdownEvent {
  /// Creates a [ProjectVoteBreakdownRequested] event.
  const ProjectVoteBreakdownRequested({
    required this.projectId,
    this.pillarName,
  });

  /// Identifier of the project or phase.
  final Hash projectId;

  /// Optional Pillar name for querying the Pillar's individual vote.
  final String? pillarName;

  @override
  List<Object?> get props => <Object?>[projectId, pillarName];
}
