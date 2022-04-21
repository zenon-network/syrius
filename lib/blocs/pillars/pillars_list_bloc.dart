import 'package:zenon_syrius_wallet_flutter/blocs/infinite_scroll_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsListBloc extends InfiniteScrollBloc<PillarInfo> {
  @override
  Future<List<PillarInfo>> getData(int pageKey, int pageSize) async =>
      (await zenon!.embedded.pillar.getAll(
        pageIndex: pageKey,
        pageSize: pageSize,
      ))
          .list;
}
