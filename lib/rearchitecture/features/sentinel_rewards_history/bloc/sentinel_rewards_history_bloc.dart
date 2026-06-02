import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches the sentinel rewards received for the last days.
class SentinelRewardsHistoryBloc extends FetchBloc<RewardHistoryList> {
  /// Creates a new instance.
  SentinelRewardsHistoryBloc({
    required super.zenon,
  }) : super(
          fromJsonT: RewardHistoryList.fromJson,
          toJsonT: (RewardHistoryList list) => list.toJson(),
        );

  @override
  Future<RewardHistoryList> getData({required Address address}) async {
    final RewardHistoryList response =
        await zenon.embedded.sentinel.getFrontierRewardByPage(
      address,
      pageSize: kStandardChartNumDays.toInt(),
    );
    if (response.list.any(
      (RewardHistoryEntry element) =>
          element.znnAmount > BigInt.zero || element.qsrAmount > BigInt.zero,
    )) {
      return response;
    }
    throw NoRewardsLastWeekException();
  }
}
