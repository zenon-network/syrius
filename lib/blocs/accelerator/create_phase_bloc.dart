import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreatePhaseBloc extends BaseBloc<AccountBlockTemplate?> {
  void createPhase(
    Hash id,
    String name,
    String description,
    String url,
    int znnFundsNeeded,
    int qsrFundsNeeded,
  ) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams =
          zenon!.embedded.accelerator.addPhase(
        id,
        name,
        description,
        url,
        znnFundsNeeded,
        qsrFundsNeeded,
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'create phase')
          .then(
        (block) => addEvent(block),
      )
          .onError(
        (error, stackTrace) {
          addError(error.toString());
        },
      );
    } catch (e) {
      addError(e);
    }
  }
}
