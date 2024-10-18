import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class UndelegateButtonBloc extends BaseBloc<AccountBlockTemplate?> {
  void cancelPillarVoting(BuildContext context) {
    try {
      addEvent(null);
      final transactionParams =
          zenon!.embedded.pillar.undelegate();
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'undelegate',
        waitForRequiredPlasma: true,
      ).then(
        (response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
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
