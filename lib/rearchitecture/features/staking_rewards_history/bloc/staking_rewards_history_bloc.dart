import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/stake_collect/utils/stake_reward_utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches the staking rewards received for the last days.
class StakingRewardsHistoryBloc extends FetchBloc<RewardHistoryList> {
  /// Creates a new instance.
  StakingRewardsHistoryBloc({
    required super.zenon,
  }) : super(
         fromJsonT: RewardHistoryList.fromJson,
         toJsonT: (RewardHistoryList list) => list.toJson(),
       );

  @override
  Future<RewardHistoryList> getData({required Address address}) async {
    final RewardHistoryList response = await zenon.embedded.stake
        .getFrontierRewardByPage(
          address,
          pageSize: kStandardChartNumDays.toInt(),
        );

    if (hasStakingRewardHistory(response.list)) {
      return response;
    }

    throw NoRewardsLastWeekException();
  }
}
