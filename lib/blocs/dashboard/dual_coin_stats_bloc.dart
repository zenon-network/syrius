import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DualCoinStatsBloc extends DashboardBaseBloc<List<Token?>> {
  @override
  Future<List<Token?>> makeAsyncCall() async => Future.wait(
        [
          zenon!.embedded.token.getByZts(
            kZnnCoin.tokenStandard,
          ),
          zenon!.embedded.token.getByZts(
            kQsrCoin.tokenStandard,
          ),
        ],
      );
}
