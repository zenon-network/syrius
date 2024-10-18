import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RealtimeStatisticsBloc extends DashboardBaseBloc<List<AccountBlock>> {
  @override
  Future<List<AccountBlock>> makeAsyncCall() async {
    final chainHeight = (await zenon!.ledger.getFrontierMomentum()).height;
    final height = chainHeight - kMomentumsPerWeek > 0
        ? chainHeight - kMomentumsPerWeek
        : 1;
    var pageIndex = 0;
    const pageSize = 10;
    var isLastPage = false;
    final blockList = <AccountBlock>[];

    while (!isLastPage) {
      final response = (await zenon!.ledger.getAccountBlocksByPage(
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
