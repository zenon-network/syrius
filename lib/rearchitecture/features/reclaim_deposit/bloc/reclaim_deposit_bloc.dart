import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'reclaim_deposit_event.dart';

part 'reclaim_deposit_state.dart';

/// Reclaims an expired deposit owned by the wallet.
class ReclaimDepositBloc
    extends Bloc<ReclaimDepositEvent, ReclaimDepositState> {
  /// Creates a [ReclaimDepositBloc].
  ReclaimDepositBloc({
    required this._accountBlockUtils,
    required this._walletAddresses,
    required this._zenon,
    required this._zenonAddressUtils,
    int Function()? unixTimeProvider,
  }) : _unixTimeProvider = unixTimeProvider ?? _currentUnixTime,
       super(const ReclaimDepositInitial()) {
    on<ReclaimDepositRequested>(_onReclaimDepositRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Set<String> _walletAddresses;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;
  final int Function() _unixTimeProvider;

  static int _currentUnixTime() => DateTime.now().unixTimestamp;

  FutureOr<void> _onReclaimDepositRequested(
    ReclaimDepositRequested event,
    Emitter<ReclaimDepositState> emit,
  ) async {
    try {
      emit(const ReclaimDepositLoading());

      final HtlcInfo htlc = await _zenon.embedded.htlc.getById(event.depositId);

      // TODO(maznnwell): this can trigger bugs: user has 10 addresses,
      // initiates swap from the 10th one, resets his wallet, has generated
      // only 3 addresses, so this check fails
      if (!_walletAddresses.contains(htlc.timeLocked.toString())) {
        throw SyriusException('The deposit does not belong to you.');
      }

      if (htlc.expirationTime - _unixTimeProvider() > 0) {
        final String expirationDate = FormatUtils.formatDate(
          htlc.expirationTime * Duration.millisecondsPerSecond,
          dateFormat: kDefaultDateTimeFormat,
        );
        throw SyriusException('The deposit is locked until $expirationDate.');
      }

      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .reclaim(event.depositId);
      final AccountBlockTemplate block = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'reclaim deposit',
            address: htlc.timeLocked,
            waitForRequiredPlasma: true,
          );

      _zenonAddressUtils.refreshBalance();
      emit(ReclaimDepositDone(block: block));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(ReclaimDepositFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(ReclaimDepositFailure(exception: FailureException()));
    }
  }
}
