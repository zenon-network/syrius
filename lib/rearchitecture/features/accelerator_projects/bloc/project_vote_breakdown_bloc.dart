import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'project_vote_breakdown_event.dart';
part 'project_vote_breakdown_state.dart';

/// Loads vote counts and the active Pillar's vote for a project or phase.
class ProjectVoteBreakdownBloc
    extends Bloc<ProjectVoteBreakdownEvent, ProjectVoteBreakdownState> {
  /// Creates a [ProjectVoteBreakdownBloc].
  ProjectVoteBreakdownBloc({required this._zenon})
    : super(const ProjectVoteBreakdownInitial()) {
    on<ProjectVoteBreakdownRequested>(
      _onProjectVoteBreakdownRequested,
      transformer: restartable(),
    );
  }

  final Zenon _zenon;

  Future<void> _onProjectVoteBreakdownRequested(
    ProjectVoteBreakdownRequested event,
    Emitter<ProjectVoteBreakdownState> emit,
  ) async {
    emit(const ProjectVoteBreakdownLoading());

    try {
      final VoteBreakdown voteBreakdown = await _zenon.embedded.accelerator
          .getVoteBreakdown(event.projectId);
      if (emit.isDone) return;

      List<PillarVote?>? pillarVotes;
      if (event.pillarName != null) {
        pillarVotes = await _zenon.embedded.accelerator.getPillarVotes(
          event.pillarName!,
          <String>[event.projectId.toString()],
        );
        if (emit.isDone) return;
      }

      emit(
        ProjectVoteBreakdownPopulated(
          voteBreakdown: voteBreakdown,
          pillarVotes: pillarVotes,
        ),
      );
    } on SyriusException catch (e, stackTrace) {
      if (emit.isDone) return;
      addError(e, stackTrace);
      emit(ProjectVoteBreakdownFailure(exception: e));
    } on Object catch (e, stackTrace) {
      if (emit.isDone) return;
      addError(e, stackTrace);
      emit(ProjectVoteBreakdownFailure(exception: FailureException()));
    }
  }
}
