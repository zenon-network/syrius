import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinel_deposit_qsr_event.dart';

part 'sentinel_deposit_qsr_state.dart';

/// A bloc that deposits QSR for sentinel creation.
class SentinelDepositQsrBloc
    extends Bloc<SentinelDepositQsrEvent, SentinelDepositQsrState> {
  /// Creates a new [SentinelDepositQsrBloc].
  SentinelDepositQsrBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    this._postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : super(const SentinelDepositQsrInitial()) {
    on<SentinelDepositQsrRequested>(_onDepositQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _postTransactionDelay;

  FutureOr<void> _onDepositQsrRequested(
    SentinelDepositQsrRequested event,
    Emitter<SentinelDepositQsrState> emit,
  ) async {
    try {
      emit(const SentinelDepositQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.sentinel
          .depositQsr(event.amount);

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'deposit ${kQsrCoin.symbol} for Sentinel Slot',
        address: event.address,
        waitForRequiredPlasma: true,
      );

      await Future<void>.delayed(_postTransactionDelay);

      _zenonAddressUtils.refreshBalance();

      emit(const SentinelDepositQsrDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(SentinelDepositQsrFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(SentinelDepositQsrFailure(exception: FailureException()));
    }
  }
}
