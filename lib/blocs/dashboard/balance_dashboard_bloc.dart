import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BalanceDashboardBloc extends DashboardBaseBloc<AccountInfo> {
  @override
  Future<AccountInfo> makeAsyncCall() async {
    AccountInfo response = await zenon!.ledger
        .getAccountInfoByAddress(Address.parse(kSelectedAddress!));
    if (response.blockCount! > 0 &&
        (response.znn()! > BigInt.zero || response.qsr()! > BigInt.zero)) {
      return response;
    } else {
      throw 'Empty balance on the selected address';
    }
  }
}
