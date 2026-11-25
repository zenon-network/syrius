import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'vote_project_event.dart';
part 'vote_project_state.dart';

/// Submits Accelerator project or phase votes using either `voteByName`
/// (Pillar owner address) or `voteByProdAddress` (Pillar producer address).
class VoteProjectBloc extends Bloc<VoteProjectEvent, VoteProjectState> {
  /// Creates a [VoteProjectBloc].
  VoteProjectBloc({
    required this._accountBlockUtils,
    required this._zenon,
    this._pageSize = kPillarRegistryPageSize,
  }) : super(const VoteProjectInitial()) {
    on<VoteProjectRequested>(_onVoteProjectRequested, transformer: droppable());
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final int _pageSize;

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
      emit(VoteProjectDone(accountBlock: block));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(VoteProjectFailure(exception: e));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(VoteProjectFailure(exception: FailureException()));
    }
  }
}
