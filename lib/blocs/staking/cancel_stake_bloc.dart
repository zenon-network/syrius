import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CancelStakeBloc extends BaseBloc<AccountBlockTemplate?> {
  void cancelStake(String hash, BuildContext context) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.stake.cancel(
        Hash.parse(hash),
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'cancel stake',
        waitForRequiredPlasma: true,
      ).then(
        (response) {
          AddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error.toString());
        },
      );
    } catch (e) {
      addError(e);
    }
  }
}
