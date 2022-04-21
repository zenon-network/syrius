import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BalanceBloc extends BaseBloc<Map<String, AccountInfo>?>
    with RefreshBlocMixin {
  BalanceBloc() {
    listenToWsRestart(getBalanceForAllAddresses);
  }

  Future<void> getBalanceForAllAddresses() async {
    try {
      addEvent(null);
      Map<String, AccountInfo> addressBalanceMap = {};
      List<AccountInfo> accountInfoList = await Future.wait(
        kDefaultAddressList.map(
          (address) => _getBalancePerAddress(
            address!,
          ),
        ),
      );
      for (var accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }
      addEvent(addressBalanceMap);
    } catch (e) {
      addError(e);
    }
  }

  Future<AccountInfo> _getBalancePerAddress(String address) async =>
      await zenon!.ledger.getAccountInfoByAddress(Address.parse(address));
}
