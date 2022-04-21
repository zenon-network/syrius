import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingOptionsBloc extends BaseBloc<AccountBlockTemplate?> {
  void stakeForQsr(
    Duration stakeDuration,
    String amount,
  ) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.stake.stake(
        stakeDuration.inSeconds,
        amount.toNum().extractDecimals(znnDecimals),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'create stake',
              waitForRequiredPlasma: true)
          .then(
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
