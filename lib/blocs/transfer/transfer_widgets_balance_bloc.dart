import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TransferWidgetsBalanceBloc extends BaseBloc<Map<String, AccountInfo>?>
    with RefreshBlocMixin {
  TransferWidgetsBalanceBloc() {
    listenToWsRestart(getBalanceForAllAddresses);
  }

  Future<void> getBalanceForAllAddresses() async {
    try {
      addEvent(null);
      final Map<String, AccountInfo> addressBalanceMap = <String, AccountInfo>{};
      final List<AccountInfo> accountInfoList = await Future.wait(
        kDefaultAddressList.map(
          (String? address) => _getBalancePerAddress(address!),
        ),
      );
      for (final AccountInfo accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }
      addEvent(addressBalanceMap);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  Future<AccountInfo> _getBalancePerAddress(String address) async =>
      zenon!.ledger.getAccountInfoByAddress(
        Address.parse(address),
      );
}
