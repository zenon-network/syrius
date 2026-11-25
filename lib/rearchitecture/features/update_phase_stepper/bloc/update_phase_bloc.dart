import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'update_phase_event.dart';
part 'update_phase_state.dart';

/// Updates an Accelerator project's current voting phase on-chain.
class UpdatePhaseBloc extends Bloc<UpdatePhaseEvent, UpdatePhaseState> {
  /// Creates an [UpdatePhaseBloc].
  UpdatePhaseBloc({required this._accountBlockUtils, required this._zenon})
    : super(const UpdatePhaseInitial()) {
    on<UpdatePhaseRequested>(_onUpdatePhaseRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;

  Future<void> _onUpdatePhaseRequested(
    UpdatePhaseRequested event,
    Emitter<UpdatePhaseState> emit,
  ) async {
    emit(const UpdatePhaseLoading());

    try {
      final AccountBlockTemplate transactionParams = _zenon.embedded.accelerator
          .updatePhase(
            event.projectId,
            event.name,
            event.description,
            event.url,
            event.znnFundsNeeded,
            event.qsrFundsNeeded,
          );
      final AccountBlockTemplate block = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'update phase',
            address: event.address,
          );
      emit(UpdatePhaseDone(accountBlock: block));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UpdatePhaseFailure(exception: e));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UpdatePhaseFailure(exception: FailureException()));
    }
  }
}
