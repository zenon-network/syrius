import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GetPillarByOwnerBloc extends BaseBlocWithRefreshMixin<List<PillarInfo>> {
  @override
  Future<List<PillarInfo>> getDataAsync() => zenon!.embedded.pillar.getByOwner(
        Address.parse(kSelectedAddress!),
      );
}
