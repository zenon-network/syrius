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
  /// Creates a new [PillarWithdrawQsrBloc].
  ///
  /// Snapshots the pre-transaction deposit within [_snapshotReadTimeout], then
  /// polls `pillar.getDepositedQsr` every [_pollInterval] up to
  /// [_confirmationTimeout] after block submission so the withdrawal is
  /// reflected on-chain before emitting [PillarWithdrawQsrPopulated].
  PillarWithdrawQsrBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    this._pollInterval = kDefaultConfirmationPollInterval,
    this._confirmationTimeout = kDefaultConfirmationTimeout,
    this._snapshotReadTimeout = kDefaultSnapshotReadTimeout,
  }) : super(const PillarWithdrawQsrInitial()) {
    on<PillarWithdrawQsrRequested>(_onWithdrawQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _pollInterval;
  final Duration _confirmationTimeout;
  final Duration _snapshotReadTimeout;

  FutureOr<void> _onWithdrawQsrRequested(
    PillarWithdrawQsrRequested event,
    Emitter<PillarWithdrawQsrState> emit,
  ) async {
    try {
      emit(const PillarWithdrawQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .withdrawQsr();
      final BigInt? initialDepositedQsr = await _readDepositedQsr(
        event.address,
      );
      if (isClosed) {
        return;
      }

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'withdraw ${kQsrCoin.symbol} from Pillar Slot',
        address: event.address,
        waitForRequiredPlasma: true,
      );
      if (isClosed) {
        return;
      }

      if (initialDepositedQsr == null || initialDepositedQsr > BigInt.zero) {
        await pollUntilConfirmed<BigInt>(
          fetch: () => _zenon.embedded.pillar.getDepositedQsr(event.address),
          isConfirmed: (BigInt deposited) => initialDepositedQsr != null
              ? deposited < initialDepositedQsr
              : deposited == BigInt.zero,
          pollInterval: _pollInterval,
          timeout: _confirmationTimeout,
          isCancelled: () => isClosed,
        );
      }

      if (isClosed) {
        return;
      }

      _zenonAddressUtils.refreshBalance();

      emit(const PillarWithdrawQsrPopulated());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed) {
        emit(PillarWithdrawQsrFailure(exception: e));
      }
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      if (!isClosed) {
        emit(PillarWithdrawQsrFailure(exception: FailureException()));
      }
    }
  }

  Future<BigInt?> _readDepositedQsr(Address address) async {
    try {
      return await _zenon.embedded.pillar
          .getDepositedQsr(address)
          .timeout(_snapshotReadTimeout);
    } on Object {
      return null;
    }
  }
}
