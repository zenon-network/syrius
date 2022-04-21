import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsDepositQsrBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> depositQsr(
    String amount, {
    bool justMarkStepCompleted = false,
  }) async {
    try {
      addEvent(null);
      if (!justMarkStepCompleted) {
        AccountBlockTemplate transactionParams =
            zenon!.embedded.pillar.depositQsr(
          amount.toNum().extractDecimals(qsrDecimals),
        );
        AccountBlockUtils.createAccountBlock(
          transactionParams,
          'deposit ${kQsrCoin.symbol} for Pillar Slot',
          waitForRequiredPlasma: true,
        ).then(
          (response) async {
            await Future.delayed(
              kDelayAfterAccountBlockCreationCall,
            );
            AddressUtils.refreshBalance();
            addEvent(response);
          },
        ).onError(
          (error, stackTrace) {
            addError(error.toString());
          },
        );
      }
    } catch (e) {
      addError(e);
    }
  }
}
