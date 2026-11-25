import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'create_phase_event.dart';
part 'create_phase_state.dart';

/// Submits a new phase for an Accelerator project on-chain.
class CreatePhaseBloc extends Bloc<CreatePhaseEvent, CreatePhaseState> {
  /// Creates a [CreatePhaseBloc].
  CreatePhaseBloc({required this._accountBlockUtils, required this._zenon})
    : super(const CreatePhaseInitial()) {
    on<CreatePhaseRequested>(_onCreatePhaseRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;

  Future<void> _onCreatePhaseRequested(
    CreatePhaseRequested event,
    Emitter<CreatePhaseState> emit,
  ) async {
    emit(const CreatePhaseLoading());

    try {
      final AccountBlockTemplate transactionParams = _zenon.embedded.accelerator
          .addPhase(
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
            'create phase',
            address: event.address,
          );
      emit(CreatePhaseDone(accountBlock: block));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CreatePhaseFailure(exception: e));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CreatePhaseFailure(exception: FailureException()));
    }
  }
}
