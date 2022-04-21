import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc_with_refresh_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GetSentinelByOwnerBloc extends BaseBlocWithRefreshMixin<SentinelInfo?> {
  @override
  Future<SentinelInfo?> getDataAsync() => zenon!.embedded.sentinel.getByOwner(
        Address.parse(kSelectedAddress!),
      );
}
