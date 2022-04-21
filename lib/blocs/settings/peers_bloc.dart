import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc_with_refresh_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PeersBloc extends BaseBlocWithRefreshMixin<NetworkInfo> {
  @override
  Future<NetworkInfo> getDataAsync() async => await zenon!.stats.networkInfo();
}
