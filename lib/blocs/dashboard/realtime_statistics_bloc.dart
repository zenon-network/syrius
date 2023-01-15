import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RealtimeStatisticsBloc extends DashboardBaseBloc<List<AccountBlock>> {
  @override
  Future<List<AccountBlock>> makeAsyncCall() async {
    int chainHeight = (await zenon!.ledger.getFrontierMomentum()).height;
    int height = chainHeight - kMomentumsPerWeek > 0
        ? chainHeight - kMomentumsPerWeek
        : 2;
    List<AccountBlock> response = (await zenon!.ledger.getAccountBlocksByHeight(
          Address.parse(kSelectedAddress!),
          height == 0 ? 0 : height - 1,
        ))
            .list ??
        [];
    if (response.isNotEmpty) {
      return response;
    } else {
      throw 'No available data';
    }
  }
}
