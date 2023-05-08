import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsDeployBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> deploySentinel(BigInt amount) async {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams =
          zenon!.embedded.sentinel.register();
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'register Sentinel',
        waitForRequiredPlasma: true,
      ).then(
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
