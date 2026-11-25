import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PeersBloc extends BaseBlocWithRefreshMixin<NetworkInfo> {
  @override
  Future<NetworkInfo> getDataAsync() async => zenon!.stats.networkInfo();
}
