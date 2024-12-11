import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CancelStakeBloc extends BaseBloc<AccountBlockTemplate?> {
  void cancelStake(String hash, BuildContext context) {
    try {
      addEvent(null);
      final AccountBlockTemplate transactionParams = zenon!.embedded.stake.cancel(
        Hash.parse(hash),
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'cancel stake',
        waitForRequiredPlasma: true,
      ).then(
        (AccountBlockTemplate response) {
          ZenonAddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        addError,
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
