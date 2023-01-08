import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreateProjectBloc extends BaseBloc<AccountBlockTemplate?> {
  void createProject(
    String name,
    String description,
    String url,
    int znnFundsNeeded,
    int qsrFundsNeeded,
  ) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams =
          zenon!.embedded.accelerator.createProject(
        name,
        description,
        url,
        znnFundsNeeded,
        qsrFundsNeeded,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'creating project',
      ).then(
        (block) {
          AddressUtils.refreshBalance();
          addEvent(block);
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
