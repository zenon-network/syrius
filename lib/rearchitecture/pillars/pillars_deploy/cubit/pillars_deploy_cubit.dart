import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillar_widgets/pillar_stepper_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_deploy_cubit.g.dart';

part 'pillars_deploy_state.dart';

/// A cubit responsible for handling the deployment of a Pillar.
class PillarsDeployCubit extends HydratedCubit<PillarsDeployState> {
  /// Creates a new instance of [PillarsDeployCubit].
  PillarsDeployCubit({
    required this.zenon,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
  })  : zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        super(const PillarsDeployState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Initiates the deployment of a Pillar with the given parameters.
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
      emit(state.copyWith(status: PillarsDeployStatus.loading));

      if (await _pillarNameAlreadyExists(pillarName)) {
        throw PillarNameAlreadyExistsException();
      }

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.register(
        pillarName,
        Address.parse(blockProducingAddress),
        Address.parse(rewardAddress),
        giveBlockRewardPercentage,
        giveDelegateRewardPercentage,
      );

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'register Pillar',
        waitForRequiredPlasma: true,
      );

      await zenonAddressUtilsHelper.refreshBalance();

      emit(
        state.copyWith(
          status: PillarsDeployStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PillarsDeployStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Checks if the pillar name already exists on the network.
  Future<bool> _pillarNameAlreadyExists(String pillarName) async =>
      !(await zenon.embedded.pillar.checkNameAvailability(pillarName));

  /// Deserializes the [PillarsDeployState] from the provided JSON [Map].
  @override
  PillarsDeployState? fromJson(Map<String, dynamic> json) =>
      PillarsDeployState.fromJson(json);

  /// Serializes the current [PillarsDeployState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(PillarsDeployState state) => state.toJson();
}
