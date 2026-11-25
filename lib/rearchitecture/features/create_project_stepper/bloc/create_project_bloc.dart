import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'create_project_event.dart';
part 'create_project_state.dart';

/// Submits a new Accelerator project on-chain.
class CreateProjectBloc extends Bloc<CreateProjectEvent, CreateProjectState> {
  /// Creates a [CreateProjectBloc].
  CreateProjectBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const CreateProjectInitial()) {
    on<CreateProjectRequested>(
      _onCreateProjectRequested,
      transformer: droppable(),
    );
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  Future<void> _onCreateProjectRequested(
    CreateProjectRequested event,
    Emitter<CreateProjectState> emit,
  ) async {
    emit(const CreateProjectLoading());

    final AccountBlockTemplate block;
    try {
      final AccountBlockTemplate transactionParams = _zenon.embedded.accelerator
          .createProject(
            event.name,
            event.description,
            event.url,
            event.znnFundsNeeded,
            event.qsrFundsNeeded,
          );
      block = await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'creating project',
        address: event.address,
      );
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CreateProjectFailure(exception: e));
      return;
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CreateProjectFailure(exception: FailureException()));
      return;
    }

    try {
      _zenonAddressUtils.refreshBalance();
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
    }
    emit(CreateProjectDone(accountBlock: block));
  }
}
