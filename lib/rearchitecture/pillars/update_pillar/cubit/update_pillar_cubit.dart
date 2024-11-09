import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'update_pillar_cubit.g.dart';
part 'update_pillar_state.dart';

/// A cubit responsible for handling the update of a Pillar's details.
class UpdatePillarCubit extends HydratedCubit<UpdatePillarState> {
  /// Creates a new instance of [UpdatePillarCubit].
  UpdatePillarCubit({
    required this.zenon,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
  })  : accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        super(const UpdatePillarState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Initiates the update of a Pillar's details with the given parameters.
  Future<void> updatePillar(
    String name,
    Address producerAddress,
    Address rewardAddress,
    int giveBlockRewardPercentage,
    int giveDelegateRewardPercentage,
  ) async {
    try {
      emit(state.copyWith(status: UpdatePillarStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.updatePillar(
        name,
        producerAddress,
        rewardAddress,
        giveBlockRewardPercentage,
        giveDelegateRewardPercentage,
      );

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'update pillar',
      );

      emit(
        state.copyWith(
          status: UpdatePillarStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UpdatePillarStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the [UpdatePillarState] from the provided JSON [Map].
  @override
  UpdatePillarState? fromJson(Map<String, dynamic> json) =>
      UpdatePillarState.fromJson(json);

  /// Serializes the current [UpdatePillarState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(UpdatePillarState state) => state.toJson();
}
