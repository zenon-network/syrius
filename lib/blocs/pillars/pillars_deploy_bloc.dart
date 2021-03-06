import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillars_stepper_container.dart';
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
      AccountBlockTemplate transactionParams =
          pillarType != PillarType.legacyPillar
              ? zenon!.embedded.pillar.register(
                  pillarName,
                  Address.parse(blockProducingAddress),
                  Address.parse(rewardAddress),
                  giveBlockRewardPercentage,
                  giveDelegateRewardPercentage,
                )
              : zenon!.embedded.pillar.registerLegacy(
                  pillarName,
                  Address.parse(blockProducingAddress),
                  Address.parse(rewardAddress),
                  publicKey!,
                  signature!,
                  giveBlockRewardPercentage,
                  giveDelegateRewardPercentage,
                );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'register Pillar',
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

  Future<bool> _pillarNameAlreadyExists(String pillarName) async =>
      !(await zenon!.embedded.pillar.checkNameAvailability(
        pillarName,
      ));
}
