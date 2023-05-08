import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingOptionsBloc extends BaseBloc<AccountBlockTemplate?> {
  void stakeForQsr(
    Duration stakeDuration,
    BigInt amount,
  ) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.stake.stake(
        stakeDuration.inSeconds,
        amount,
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'create stake',
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
