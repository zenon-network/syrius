import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsDepositQsrBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> depositQsr(
    BigInt amount, {
    bool justMarkStepCompleted = false,
  }) async {
    try {
      addEvent(null);
      if (!justMarkStepCompleted) {
        AccountBlockTemplate transactionParams =
            zenon!.embedded.sentinel.depositQsr(
          amount,
        );
        AccountBlockUtils.createAccountBlock(
          transactionParams,
          'deposit ${kQsrCoin.symbol} for Sentinel Slot',
          waitForRequiredPlasma: true,
        ).then(
          (response) async {
            await Future.delayed(
              kDelayAfterAccountBlockCreationCall,
            );
            ZenonAddressUtils.refreshBalance();
            addEvent(response);
          },
        ).onError(
          (error, stackTrace) {
            addError(error, stackTrace);
          },
        );
      }
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
