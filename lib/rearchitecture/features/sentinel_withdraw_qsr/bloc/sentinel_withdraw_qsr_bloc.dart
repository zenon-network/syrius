import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_withdraw_qsr_event.dart';

part 'sentinel_withdraw_qsr_state.dart';

/// A bloc that withdraws QSR deposited for sentinel creation.
class SentinelWithdrawQsrBloc
    extends Bloc<SentinelWithdrawQsrEvent, SentinelWithdrawQsrState> {
  /// Creates a new [SentinelWithdrawQsrBloc].
  SentinelWithdrawQsrBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    this._postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : super(const SentinelWithdrawQsrInitial()) {
    on<SentinelWithdrawQsrRequested>(_onWithdrawQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _postTransactionDelay;

  FutureOr<void> _onWithdrawQsrRequested(
    SentinelWithdrawQsrRequested event,
    Emitter<SentinelWithdrawQsrState> emit,
  ) async {
    try {
      emit(const SentinelWithdrawQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.sentinel
          .withdrawQsr();

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'withdraw ${kQsrCoin.symbol} from Sentinel Slot',
        address: event.address,
        waitForRequiredPlasma: true,
      );

      await Future<void>.delayed(_postTransactionDelay);

      _zenonAddressUtils.refreshBalance();

      emit(const SentinelWithdrawQsrPopulated());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(SentinelWithdrawQsrFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(SentinelWithdrawQsrFailure(exception: FailureException()));
    }
  }
}
