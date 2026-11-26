import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'vote_project_event.dart';
part 'vote_project_state.dart';

/// Submits Accelerator project or phase votes using either `voteByName`
/// (Pillar owner address) or `voteByProdAddress` (Pillar producer address).
class VoteProjectBloc extends Bloc<VoteProjectEvent, VoteProjectState> {
  /// Creates a [VoteProjectBloc].
  ///
  /// After publishing the vote account block, polls
  /// `accelerator.getPillarVotes` every [_pollInterval] up to
  /// [_confirmationTimeout] so the newly cast vote is confirmed on-chain before
  /// emitting [VoteProjectDone] and triggering a breakdown refresh.
  VoteProjectBloc({
    required this._accountBlockUtils,
    required this._zenon,
    this._pageSize = kPillarRegistryPageSize,
    this._pollInterval = kDefaultConfirmationPollInterval,
    this._confirmationTimeout = kDefaultConfirmationTimeout,
  }) : super(const VoteProjectInitial()) {
    on<VoteProjectRequested>(_onVoteProjectRequested, transformer: droppable());
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final int _pageSize;
  final Duration _pollInterval;
  final Duration _confirmationTimeout;

  Future<void> _onVoteProjectRequested(
    VoteProjectRequested event,
    Emitter<VoteProjectState> emit,
  ) async {
    emit(const VoteProjectLoading());

    try {
      final ResolvedPillarResult resolved = await resolvePillarForAddress(
        zenon: _zenon,
        address: event.address,
        pageSize: _pageSize,
      );
      if (isClosed || emit.isDone) {
        return;
      }

      final PillarInfo? pillarInfo = resolved.pillarInfo;
      if (pillarInfo == null) {
        emit(VoteProjectFailure(exception: NoPillarForAddressException()));
        return;
      }

      final AccountBlockTemplate transactionParams =
          voteMethodFor(pillarInfo, event.address) ==
              AcceleratorVoteMethod.byName
          ? _zenon.embedded.accelerator.voteByName(
              event.id,
              pillarInfo.name,
              event.vote.index,
            )
          : _zenon.embedded.accelerator.voteByProdAddress(
              event.id,
              event.vote.index,
            );

      // Pin the signing account to the address captured in the event so that
      // role resolution and signing always use the same account.
      final AccountBlockTemplate block = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'vote for project',
            address: event.address,
          );
      if (isClosed || emit.isDone) {
        return;
      }

      await pollUntilConfirmed<List<PillarVote?>>(
        fetch: () => _zenon.embedded.accelerator.getPillarVotes(
          pillarInfo.name,
          <String>[event.id.toString()],
        ),
        isConfirmed: (List<PillarVote?> pillarVotes) => _isVoteConfirmed(
          pillarVotes,
          projectId: event.id,
          pillarName: pillarInfo.name,
          expectedVote: event.vote,
        ),
        pollInterval: _pollInterval,
        timeout: _confirmationTimeout,
        isCancelled: () => isClosed || emit.isDone,
      );
      if (isClosed || emit.isDone) {
        return;
      }

      emit(VoteProjectDone(accountBlock: block));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed && !emit.isDone) {
        emit(VoteProjectFailure(exception: e));
      }
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed && !emit.isDone) {
        emit(VoteProjectFailure(exception: FailureException()));
      }
    }
  }

  bool _isVoteConfirmed(
    List<PillarVote?> pillarVotes, {
    required Hash projectId,
    required String pillarName,
    required AcceleratorProjectVote expectedVote,
  }) {
    for (final PillarVote? pillarVote in pillarVotes) {
      if (pillarVote != null &&
          pillarVote.id == projectId &&
          pillarVote.name == pillarName &&
          pillarVote.vote == expectedVote.index) {
        return true;
      }
    }
    return false;
  }
}
