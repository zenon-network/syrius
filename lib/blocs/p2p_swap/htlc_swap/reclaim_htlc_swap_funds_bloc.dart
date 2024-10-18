import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReclaimHtlcSwapFundsBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> reclaimFunds({
    required Hash htlcId,
    required Address selfAddress,
  }) async {
    try {
      addEvent(null);
      final transactionParams =
          zenon!.embedded.htlc.reclaim(htlcId);
      AccountBlockUtils.createAccountBlock(
              transactionParams, 'reclaim swap funds',
              address: selfAddress, waitForRequiredPlasma: true,)
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
