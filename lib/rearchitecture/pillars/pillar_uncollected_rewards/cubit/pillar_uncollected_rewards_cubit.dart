import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubit_for_reloading_indicator.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/indicator_state.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_uncollected_rewards_cubit.g.dart';
part 'pillar_uncollected_rewards_state.dart';

/// A cubit responsible for fetching and managing the state of
/// uncollected rewards for a specific pillar address.
class PillarUncollectedRewardsCubit extends CubitForReloadingIndicator<
    UncollectedReward, PillarUncollectedRewardsState> {

  /// Constructs a [PillarUncollectedRewardsCubit]
  /// with a specified Zenon instance, the target [address] to retrieve
  /// uncollected rewards, and an optional flag [callUpdateStream] to control
  /// whether data is fetched on initialization.
  PillarUncollectedRewardsCubit({
    required super.zenon,
    required this.address,
    bool callUpdateStream = true,
  }) : super(
    callUpdateStream: callUpdateStream,
    const PillarUncollectedRewardsState(),
  );

  /// The [Address] for which the cubit fetches and manages uncollected rewards.
  final Address address;

  /// Fetches the uncollected rewards for the specified [address].
  @override
  Future<UncollectedReward> getData() async {
    try {
      final UncollectedReward response =
      await zenon.embedded.pillar.getUncollectedReward(address);
      return response;
    } catch (e) {
      rethrow;
    }
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
