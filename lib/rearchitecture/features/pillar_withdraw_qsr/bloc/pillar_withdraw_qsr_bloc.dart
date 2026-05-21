import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_withdraw_qsr_event.dart';

part 'pillar_withdraw_qsr_state.dart';

class PillarWithdrawQsrBloc extends Bloc<PillarWithdrawQsrEvent, PillarWithdrawQsrState> {
  PillarWithdrawQsrBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
    required ZenonAddressUtils zenonAddressUtils,
  }) : _zenonAddressUtils = zenonAddressUtils,
       _accountBlockUtils = accountBlockUtils,
       _zenon = zenon,
       super(const PillarWithdrawQsrInitial()) {
    on<PillarWithdrawQsrRequested>(_onWithdrawQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onWithdrawQsrRequested(
    PillarWithdrawQsrRequested event,
    Emitter<PillarWithdrawQsrState> emit,
  ) async {
    try {
      emit(const PillarWithdrawQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .withdrawQsr();

      await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'withdraw ${kQsrCoin.symbol} from Pillar Slot',
            waitForRequiredPlasma: true,
          );

      // TODO: check if this delay should be in place
      await Future<void>.delayed(kDelayAfterAccountBlockCreationCall);

      _zenonAddressUtils.refreshBalance();

      emit(const PillarWithdrawQsrPopulated());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(PillarWithdrawQsrFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(PillarWithdrawQsrFailure(exception: FailureException()));
    }
  }
}
