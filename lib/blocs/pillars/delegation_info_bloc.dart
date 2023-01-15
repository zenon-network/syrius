import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DelegationInfoBloc extends BaseBlocWithRefreshMixin<DelegationInfo?> {
  @override
  Future<DelegationInfo?> getDataAsync() =>
      zenon!.embedded.pillar.getDelegatedPillar(
        Address.parse(kSelectedAddress!),
      );
}
