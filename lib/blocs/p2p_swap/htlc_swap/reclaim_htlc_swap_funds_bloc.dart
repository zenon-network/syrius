import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReclaimHtlcSwapFundsBloc extends BaseBloc<AccountBlockTemplate?> {
  void reclaimFunds({
    required Hash htlcId,
    required Address selfAddress,
  }) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams =
          zenon!.embedded.htlc.reclaim(htlcId);
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(selfAddress.toString()),
      );
      AccountBlockUtils.createAccountBlock(
              transactionParams, 'reclaim swap funds',
              blockSigningKey: blockSigningKeyPair, waitForRequiredPlasma: true)
          .then(
        (response) {
          ZenonAddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error.toString(), stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
