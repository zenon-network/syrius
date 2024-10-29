import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DisassembleButtonBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> disassembleSentinel(BuildContext context) async {
    try {
      addEvent(null);
      final AccountBlockTemplate transactionParams =
          zenon!.embedded.sentinel.revoke();
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'disassemble Sentinel',
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
