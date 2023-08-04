import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarRewardsHistoryBloc
    extends BaseBlocForReloadingIndicator<RewardHistoryList> {
  @override
  Future<RewardHistoryList> getDataAsync() async {
    RewardHistoryList response =
        await zenon!.embedded.pillar.getFrontierRewardByPage(
      Address.parse(kSelectedAddress!),
      pageSize: kStandardChartNumDays.toInt(),
    );
    if (response.list.any((element) => element.znnAmount > BigInt.zero)) {
      return response;
    } else {
      throw 'No rewards in the last week';
    }
  }
}
