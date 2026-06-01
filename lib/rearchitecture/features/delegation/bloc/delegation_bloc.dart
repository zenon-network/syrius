import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegation_event.dart';

part 'delegation_state.dart';

class DelegationBloc extends Bloc<DelegationEvent, DelegationState> {
  DelegationBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
    Duration postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : _accountBlockUtils = accountBlockUtils,
        _postTransactionDelay = postTransactionDelay,
        _zenon = zenon,
        super(const DelegationInitial()) {
    on<DelegationRequested>(_onDelegationRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final Duration _postTransactionDelay;

  FutureOr<void> _onDelegationRequested(
    DelegationRequested event,
    Emitter<DelegationState> emit,
  ) async {
    try {
      emit(const DelegationLoading());

      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .delegate(
            event.pillarName,
          );

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'delegate to Pillar',
        address: event.address,
        waitForRequiredPlasma: true,
      );

      await Future<void>.delayed(_postTransactionDelay);

      emit(const DelegationDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DelegationFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DelegationFailure(exception: FailureException()));
    }
  }
}
