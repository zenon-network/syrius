import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/infinite_scroll_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsListBloc extends InfiniteScrollBloc<SentinelInfo> {
  @override
  Future<List<SentinelInfo>> getData(int pageKey, int pageSize) async =>
      (await zenon!.embedded.sentinel.getAllActive(
        pageIndex: pageKey,
        pageSize: pageSize,
      ))
          .list;
}
