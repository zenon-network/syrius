import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_deposit_qsr_event.dart';

part 'pillar_deposit_qsr_state.dart';

/// A bloc that helps with depositing the needed QSR for the creation of a
/// pillar
class PillarDepositQsrBloc
    extends Bloc<PillarDepositQsrEvent, PillarDepositQsrState> {
  /// Creates a new [PillarDepositQsrBloc].
  ///
  /// Polls `pillar.getDepositedQsr` every [_pollInterval] up to
  /// [_confirmationTimeout] after block submission so the deposit is reflected
  /// on-chain before emitting [PillarDepositQsrDone]. Falls back to waiting
  /// [_postTransactionDelay] only if the pre-transaction deposit snapshot
  /// cannot be read.
  PillarDepositQsrBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    this._pollInterval = kDefaultConfirmationPollInterval,
    this._confirmationTimeout = kDefaultConfirmationTimeout,
    this._postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : super(const PillarDepositQsrInitial()) {
    on<PillarDepositQsrRequested>(_onDepositQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _pollInterval;
  final Duration _confirmationTimeout;
  final Duration _postTransactionDelay;

  FutureOr<void> _onDepositQsrRequested(
    PillarDepositQsrRequested event,
    Emitter<PillarDepositQsrState> emit,
  ) async {
    try {
      emit(const PillarDepositQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .depositQsr(event.amount);
      final BigInt? initialDepositedQsr = await _readDepositedQsr(
        event.address,
      );
      if (isClosed) {
        return;
      }

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'deposit ${kQsrCoin.symbol} from Pillar Slot',
            address: event.address,
            waitForRequiredPlasma: true,
          );
      if (isClosed) {
        return;
      }

      if (initialDepositedQsr != null) {
        final BigInt expectedDepositedQsr = initialDepositedQsr + event.amount;
        await pollUntilConfirmed<BigInt>(
          fetch: () => _zenon.embedded.pillar.getDepositedQsr(event.address),
          isConfirmed: (BigInt deposited) => deposited >= expectedDepositedQsr,
          pollInterval: _pollInterval,
          timeout: _confirmationTimeout,
          isCancelled: () => isClosed,
        );
      } else {
        await Future<void>.delayed(_postTransactionDelay);
      }

      if (isClosed) {
        return;
      }

      _zenonAddressUtils.refreshBalance();

      emit(PillarDepositQsrDone(accountBlock: response));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed) {
        emit(PillarDepositQsrFailure(exception: e));
      }
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed) {
        emit(PillarDepositQsrFailure(exception: FailureException()));
      }
    }
  }

  Future<BigInt?> _readDepositedQsr(Address address) async {
    try {
      return await _zenon.embedded.pillar.getDepositedQsr(address);
    } on Object {
      return null;
    }
  }
}
