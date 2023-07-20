import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsDeployBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> deployPillar({
    required PillarType pillarType,
    required String pillarName,
    required String rewardAddress,
    required String blockProducingAddress,
    required int giveBlockRewardPercentage,
    required int giveDelegateRewardPercentage,
    String? signature,
    String? publicKey,
  }) async {
    try {
      addEvent(null);
      if (await _pillarNameAlreadyExists(pillarName)) {
        throw 'Pillar name already exists';
      }
      AccountBlockTemplate transactionParams = zenon!.embedded.pillar.register(
        pillarName,
        Address.parse(blockProducingAddress),
        Address.parse(rewardAddress),
        giveBlockRewardPercentage,
        giveDelegateRewardPercentage,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'register Pillar',
        waitForRequiredPlasma: true,
      ).then(
        (response) {
          ZenonAddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  Future<bool> _pillarNameAlreadyExists(String pillarName) async =>
      !(await zenon!.embedded.pillar.checkNameAvailability(
        pillarName,
      ));
}
