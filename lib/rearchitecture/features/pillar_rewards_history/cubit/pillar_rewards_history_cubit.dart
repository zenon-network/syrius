import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_rewards_history_cubit.g.dart';
part 'pillar_rewards_history_state.dart';

/// A cubit that manages the state of reward history for a specific pillar
/// address.
class PillarRewardsHistoryCubit extends CubitWithRefreshMixin<
    RewardHistoryList, PillarRewardsHistoryState> {

  /// Constructs a [PillarRewardsHistoryCubit].
  PillarRewardsHistoryCubit({
    required super.zenon,
  }) : super(
    initialState: const PillarRewardsHistoryState(),
  );

  /// Fetches the reward history data for the specified [address]
  /// with the defined [kStandardChartNumDays].
  @override
  Future<RewardHistoryList> getData({required Address address}) async {
    try {
      final RewardHistoryList response =
      await zenon.embedded.pillar.getFrontierRewardByPage(
        address,
        pageSize: kStandardChartNumDays.toInt(),
      );
      if (response.list.any(
            (RewardHistoryEntry element) => element.znnAmount > BigInt.zero,
      )) {
        return response;
      } else {
        throw NoRewardsLastWeekException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [PillarRewardsHistoryState].
  @override
  PillarRewardsHistoryState? fromJson(Map<String, dynamic> json) =>
      PillarRewardsHistoryState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(PillarRewardsHistoryState state) =>
      state.toJson();
}
