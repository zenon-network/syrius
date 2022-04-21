import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DisassemblePillarBloc extends BaseBloc<AccountBlockTemplate?> {
  void disassemblePillar(
    BuildContext context,
    String pillarName,
  ) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.pillar.revoke(
        pillarName,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'disassemble Pillar',
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
