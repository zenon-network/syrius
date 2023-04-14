import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingListBloc extends InfiniteScrollBloc<StakeEntry> {
  @override
  Future<List<StakeEntry>> getData(int pageKey, int pageSize) async =>
      (await zenon!.embedded.stake.getEntriesByAddress(
        Address.parse(kSelectedAddress!),
        pageIndex: pageKey,
        pageSize: pageSize,
      ))
          .list;
}
