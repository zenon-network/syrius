part of 'project_vote_breakdown_bloc.dart';

/// Base state for [ProjectVoteBreakdownBloc].
sealed class ProjectVoteBreakdownState extends Equatable {
  /// Creates a [ProjectVoteBreakdownState].
  const ProjectVoteBreakdownState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before the vote breakdown has been requested.
final class ProjectVoteBreakdownInitial extends ProjectVoteBreakdownState {
  /// Creates a [ProjectVoteBreakdownInitial] state.
  const ProjectVoteBreakdownInitial();
}

/// State emitted while loading the vote breakdown.
final class ProjectVoteBreakdownLoading extends ProjectVoteBreakdownState {
  /// Creates a [ProjectVoteBreakdownLoading] state.
  const ProjectVoteBreakdownLoading();
}

/// State emitted when the vote breakdown has loaded.
final class ProjectVoteBreakdownPopulated extends ProjectVoteBreakdownState {
  /// Creates a [ProjectVoteBreakdownPopulated] state.
  const ProjectVoteBreakdownPopulated({
    required this.voteBreakdown,
    required this.pillarVotes,
  });

  /// Aggregate vote counts for the project or phase.
  final VoteBreakdown voteBreakdown;

  /// Current Pillar's vote entries, or `null` when no Pillar is active.
  final List<PillarVote?>? pillarVotes;

  @override
  List<Object?> get props => <Object?>[voteBreakdown, pillarVotes];
}

/// State emitted when loading the vote breakdown fails.
final class ProjectVoteBreakdownFailure extends ProjectVoteBreakdownState {
  /// Creates a [ProjectVoteBreakdownFailure] state.
  const ProjectVoteBreakdownFailure({required this.exception});

  /// Failure describing why the vote breakdown could not be loaded.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
