import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_swap_utility/znn_swap_utility.dart';

class TransferBalanceBloc extends BaseBloc<SwapFileEntry?> {
  Future<void> transferBalanceToNewAddresses(
    SwapFileEntry swapFileEntry,
    Future<KeyPair?> futureBlockSigningKeyPair,
    String passphrase,
  ) async {
    try {
      addEvent(null);
      KeyPair? blockSigningKeyPair = await futureBlockSigningKeyPair;
      Address? alphaNetAddress = await blockSigningKeyPair!.address;
      String signature = await swapFileEntry.signAssetsAsync(
        passphrase,
        alphaNetAddress!.toString(),
      );
      AccountBlockTemplate transactionParams =
          zenon!.embedded.swap.retrieveAssets(
        swapFileEntry.pubKeyB64,
        signature,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'transfer balance to new address',
        blockSigningKey: blockSigningKeyPair,
        waitForRequiredPlasma: true,
      ).then(
        (value) => addEvent(swapFileEntry),
        onError: (error) {
          addError(error);
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
