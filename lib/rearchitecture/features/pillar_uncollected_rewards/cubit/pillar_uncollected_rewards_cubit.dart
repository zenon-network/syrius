import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_uncollected_rewards_cubit.g.dart';

part 'pillar_uncollected_rewards_state.dart';

/// A cubit responsible for fetching and managing the state of
/// uncollected rewards for a specific pillar address.
class PillarUncollectedRewardsCubit extends CubitWithRefreshOption<
    UncollectedReward, PillarUncollectedRewardsState> {
  /// Constructs a [PillarUncollectedRewardsCubit]
  PillarUncollectedRewardsCubit({
    required super.zenon,
  }) : super(
          initialState: const PillarUncollectedRewardsState(),
        );

  /// Fetches the uncollected rewards for the specified [address].
  @override
  Future<UncollectedReward> getData({required Address address}) async {
    final UncollectedReward response =
        await zenon.embedded.pillar.getUncollectedReward(address);
    return response;
  }

  /// Deserializes a JSON map into a [PillarUncollectedRewardsState] instance.
  @override
  PillarUncollectedRewardsState? fromJson(Map<String, dynamic> json) =>
      PillarUncollectedRewardsState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(PillarUncollectedRewardsState state) =>
      state.toJson();
}
