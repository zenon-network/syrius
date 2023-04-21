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
        : 1;
    int pageIndex = 0;
    int pageSize = 10;
    bool isLastPage = false;
    List<AccountBlock> blockList = [];

    while (!isLastPage) {
      List<AccountBlock> response = (await zenon!.ledger.getAccountBlocksByPage(
            Address.parse(kSelectedAddress!),
            pageIndex: pageIndex,
            pageSize: pageSize,
          ))
              .list ??
          [];

      if (response.isEmpty) {
        break;
      }

      blockList.addAll(response);

      if (response.last.confirmationDetail!.momentumHeight <= height) {
        break;
      }

      pageIndex += 1;
      isLastPage = response.length < pageSize;
    }

    if (blockList.isNotEmpty) {
      return blockList;
    } else {
      throw 'No available data';
    }
  }
}
