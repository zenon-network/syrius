import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CancelPlasmaBloc extends BaseBloc<AccountBlockTemplate?> {
  void cancelPlasmaStaking(String id, BuildContext context) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.plasma.cancel(
        Hash.parse(id),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'cancel Plasma',
              waitForRequiredPlasma: true)
          .then(
        (response) {
          ZenonAddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
