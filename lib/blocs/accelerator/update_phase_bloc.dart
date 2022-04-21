import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class UpdatePhaseBloc extends BaseBloc<AccountBlockTemplate?> {
  void updatePhase(Hash id, String name, String description, String url,
      double znnFundsNeeded, double qsrFundsNeeded) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams =
          zenon!.embedded.accelerator.updatePhase(
        id,
        name,
        description,
        url,
        AmountUtils.extractDecimals(
          znnFundsNeeded,
          znnDecimals,
        ),
        AmountUtils.extractDecimals(
          qsrFundsNeeded,
          qsrDecimals,
        ),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'update phase')
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
