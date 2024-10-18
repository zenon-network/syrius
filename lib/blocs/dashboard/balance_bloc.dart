import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
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
      final addressBalanceMap = <String, AccountInfo>{};
      final accountInfoList = await Future.wait(
        kDefaultAddressList.map(
          (address) => _getBalancePerAddress(
            address!,
          ),
        ),
      );
      for (final accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }
      addEvent(addressBalanceMap);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  Future<AccountInfo> _getBalancePerAddress(String address) async =>
      zenon!.ledger.getAccountInfoByAddress(Address.parse(address));
}
