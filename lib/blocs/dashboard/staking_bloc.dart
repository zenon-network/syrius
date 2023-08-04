import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingStatsModel {
  int numActiveStakingEntries;
  BigInt totalZnnStakingAmount;

  StakingStatsModel(
    this.numActiveStakingEntries,
    this.totalZnnStakingAmount,
  );
}

class StakingBloc extends DashboardBaseBloc<StakingStatsModel> {
  @override
  Future<StakingStatsModel> makeAsyncCall() async {
    StakeList stakeList = await _getStakeList();
    if (stakeList.list.isNotEmpty) {
      return StakingStatsModel(
        stakeList.list.length,
        stakeList.totalAmount,
      );
    } else {
      throw 'No active staking entries';
    }
  }

  Future<StakeList> _getStakeList() async =>
      await zenon!.embedded.stake.getEntriesByAddress(
        Address.parse(kSelectedAddress!),
        pageIndex: 0,
      );
}
