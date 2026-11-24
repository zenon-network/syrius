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
  ///
  /// Snapshots the pre-transaction deposit within [_snapshotReadTimeout], then
  /// polls `sentinel.getDepositedQsr` every [_pollInterval] up to
  /// [_confirmationTimeout] after block submission so the deposit is reflected
  /// on-chain before emitting [SentinelDepositQsrDone]. Falls back to waiting
  /// [_postTransactionDelay] only if the pre-transaction deposit snapshot
  /// cannot be read.
  SentinelDepositQsrBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    this._pollInterval = kDefaultConfirmationPollInterval,
    this._confirmationTimeout = kDefaultConfirmationTimeout,
    this._snapshotReadTimeout = kDefaultSnapshotReadTimeout,
    this._postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : super(const SentinelDepositQsrInitial()) {
    on<SentinelDepositQsrRequested>(_onDepositQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _pollInterval;
  final Duration _confirmationTimeout;
  final Duration _snapshotReadTimeout;
  final Duration _postTransactionDelay;

  FutureOr<void> _onDepositQsrRequested(
    SentinelDepositQsrRequested event,
    Emitter<SentinelDepositQsrState> emit,
  ) async {
    try {
      emit(const SentinelDepositQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.sentinel
          .depositQsr(event.amount);
      final BigInt? initialDepositedQsr = await _readDepositedQsr(
        event.address,
      );
      if (isClosed) {
        return;
      }

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'deposit ${kQsrCoin.symbol} for Sentinel Slot',
        address: event.address,
        waitForRequiredPlasma: true,
      );
      if (isClosed) {
        return;
      }

      if (initialDepositedQsr != null) {
        final BigInt expectedDepositedQsr = initialDepositedQsr + event.amount;
        await pollUntilConfirmed<BigInt>(
          fetch: () => _zenon.embedded.sentinel.getDepositedQsr(event.address),
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

      emit(const SentinelDepositQsrDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed) {
        emit(SentinelDepositQsrFailure(exception: e));
      }
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed) {
        emit(SentinelDepositQsrFailure(exception: FailureException()));
      }
    }
  }

  Future<BigInt?> _readDepositedQsr(Address address) async {
    try {
      return await _zenon.embedded.sentinel
          .getDepositedQsr(address)
          .timeout(_snapshotReadTimeout);
    } on Object {
      return null;
    }
  }
}
