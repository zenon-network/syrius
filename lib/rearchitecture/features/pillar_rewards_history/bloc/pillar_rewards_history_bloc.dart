import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that helps with fetching the pillar rewards received for the a
/// certain number of days, e.g. for the last 7 days
class PillarRewardsHistoryBloc extends FetchBloc<RewardHistoryList> {
  ///{@template default_constructor}
  /// Creates an new instance
  /// {@endtemplate}
  PillarRewardsHistoryBloc({
    required super.zenon,
  }) : super(
         fromJsonT: RewardHistoryList.fromJson,
         toJsonT: (RewardHistoryList list) => list.toJson(),
       );

  @override
  Future<RewardHistoryList> getData({required Address address}) async {
    try {
      final RewardHistoryList response = await zenon.embedded.pillar
          .getFrontierRewardByPage(
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
}
