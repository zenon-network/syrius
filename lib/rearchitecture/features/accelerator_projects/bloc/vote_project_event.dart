part of 'vote_project_bloc.dart';

/// Base event for [VoteProjectBloc].
sealed class VoteProjectEvent extends Equatable {
  /// Creates a [VoteProjectEvent].
  const VoteProjectEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests casting a Pillar vote on an Accelerator project or phase.
final class VoteProjectRequested extends VoteProjectEvent {
  /// Creates a [VoteProjectRequested] event.
  const VoteProjectRequested({
    required this.address,
    required this.id,
    required this.vote,
  });

  /// Selected wallet address used for Pillar resolution and block signing.
  final Address address;

  /// Identifier of the project or phase being voted on.
  final Hash id;

  /// Vote choice (yes, no, or abstain).
  final AcceleratorProjectVote vote;

  @override
  List<Object?> get props => <Object?>[address, id, vote];
}
