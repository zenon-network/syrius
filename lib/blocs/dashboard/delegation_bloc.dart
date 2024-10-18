import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DelegationBloc extends DashboardBaseBloc<DelegationInfo> {
  @override
  Future<DelegationInfo> makeAsyncCall() async {
    try {
      final response =
          await zenon!.embedded.pillar.getDelegatedPillar(
        Address.parse(kSelectedAddress!),
      );
      if (response != null) {
        return response;
      } else {
        throw 'No delegation stats';
      }
    } catch (e) {
      rethrow;
    }
  }
}
