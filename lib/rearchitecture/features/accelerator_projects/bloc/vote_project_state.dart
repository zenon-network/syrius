part of 'vote_project_bloc.dart';

/// Base state for [VoteProjectBloc].
sealed class VoteProjectState extends Equatable {
  /// Creates a [VoteProjectState].
  const VoteProjectState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before any vote has been submitted.
final class VoteProjectInitial extends VoteProjectState {
  /// Creates a [VoteProjectInitial] state.
  const VoteProjectInitial();
}

/// State emitted while resolving Pillar role and publishing the vote block.
final class VoteProjectLoading extends VoteProjectState {
  /// Creates a [VoteProjectLoading] state.
  const VoteProjectLoading();
}

/// State emitted once the vote account block has been published.
final class VoteProjectDone extends VoteProjectState {
  /// Creates a [VoteProjectDone] state.
  const VoteProjectDone({required this.accountBlock});

  /// Published vote account block.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// State emitted when voting fails or the address has no Pillar role.
final class VoteProjectFailure extends VoteProjectState {
  /// Creates a [VoteProjectFailure] state.
  const VoteProjectFailure({required this.exception});

  /// Failure describing why the vote did not complete.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
