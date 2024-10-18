import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class UpdatePillarBloc extends BaseBloc<AccountBlockTemplate?> {
  void updatePillar(
    String name,
    Address producerAddress,
    Address rewardAddress,
    int giveBlockRewardPercentage,
    int giveDelegateRewardPercentage,
  ) {
    try {
      addEvent(null);
      final transactionParams =
          zenon!.embedded.pillar.updatePillar(
        name,
        producerAddress,
        rewardAddress,
        giveBlockRewardPercentage,
        giveDelegateRewardPercentage,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'update pillar',
      )
          .then(
        addEvent,
      )
          .onError(
        addError,
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
