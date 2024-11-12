import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillar_rewards_history/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubit_for_reloading_indicator.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/indicator_state.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_rewards_history_cubit.g.dart';
part 'pillar_rewards_history_state.dart';

/// A cubit that manages the state of reward history for a specific pillar
/// address.
class PillarRewardsHistoryCubit extends CubitForReloadingIndicator<
    RewardHistoryList, PillarRewardsHistoryState> {

  /// Constructs a [PillarRewardsHistoryCubit] with the necessary Zenon
  /// instance, the target [address] for which reward history data is fetched,
  /// and an optional [pageSize] to control the number of entries retrieved.
  PillarRewardsHistoryCubit({
    required super.zenon,
    required this.address,
    this.pageSize = kStandardChartNumDays,
    bool callUpdateStream = true,
  }) : super(
    callUpdateStream: callUpdateStream,
    const PillarRewardsHistoryState(),
  );

  /// The [Address] for which the cubit fetches and manages reward history data.
  final Address address;

  /// The number of reward history entries to request per page.
  final double pageSize;

  /// Fetches the reward history data for the specified [address]
  /// with the defined [pageSize].
  @override
  Future<RewardHistoryList> getData() async {
    try {
      final RewardHistoryList response =
      await zenon.embedded.pillar.getFrontierRewardByPage(
        address,
        pageSize: pageSize.toInt(),
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
