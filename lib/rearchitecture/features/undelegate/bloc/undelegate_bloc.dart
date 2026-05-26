import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'undelegate_event.dart';

part 'undelegate_state.dart';

class UndelegateBloc extends Bloc<UndelegateEvent, UndelegateState> {
  UndelegateBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
  }) : _accountBlockUtils = accountBlockUtils,
       _zenon = zenon,
       super(const UndelegateInitial()) {
    on<UndelegateRequested>(_onUndelegateRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;

  FutureOr<void> _onUndelegateRequested(
    UndelegateRequested event,
    Emitter<UndelegateState> emit,
  ) async {
    try {
      emit(const UndelegateLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .undelegate();
      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'undelegate',
        address: event.address,
        waitForRequiredPlasma: true,
      );

      await Future<void>.delayed(kDelayAfterAccountBlockCreationCall);

      emit(const UndelegateDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UndelegateFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UndelegateFailure(exception: FailureException()));
    }
  }
}
