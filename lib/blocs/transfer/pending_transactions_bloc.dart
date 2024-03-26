import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PendingTransactionsBloc extends InfiniteScrollBloc<AccountBlock> {
  @override
  Future<List<AccountBlock>> getData(int pageKey, int pageSize) async =>
      (await zenon!.ledger.getUnreceivedBlocksByAddress(
        Address.parse(kSelectedAddress!),
        pageIndex: pageKey,
        pageSize: pageSize,
      ))
          .list!;
}
