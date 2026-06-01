import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_withdraw_qsr_event.dart';

part 'pillar_withdraw_qsr_state.dart';

/// A bloc that helps with withdrawing the deposited QSR for the pillar
/// creation
class PillarWithdrawQsrBloc
    extends Bloc<PillarWithdrawQsrEvent, PillarWithdrawQsrState> {
  /// {@macro default_constructor}
  PillarWithdrawQsrBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
    required ZenonAddressUtils zenonAddressUtils,
    Duration postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : _zenonAddressUtils = zenonAddressUtils,
        _postTransactionDelay = postTransactionDelay,
        _accountBlockUtils = accountBlockUtils,
        _zenon = zenon,
        super(const PillarWithdrawQsrInitial()) {
    on<PillarWithdrawQsrRequested>(_onWithdrawQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _postTransactionDelay;

  FutureOr<void> _onWithdrawQsrRequested(
    PillarWithdrawQsrRequested event,
    Emitter<PillarWithdrawQsrState> emit,
  ) async {
    try {
      emit(const PillarWithdrawQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .withdrawQsr();

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'withdraw ${kQsrCoin.symbol} from Pillar Slot',
        address: event.address,
        waitForRequiredPlasma: true,
      );

      // Needed delay to make sure that the blockchain synced
      await Future<void>.delayed(_postTransactionDelay);

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
