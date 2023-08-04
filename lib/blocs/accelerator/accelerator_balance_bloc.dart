import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AcceleratorBalanceBloc extends BaseBloc<AccountInfo?> {
  Future<void> getAcceleratorBalance() async {
    try {
      addEvent(null);
      AccountInfo accountInfo = await zenon!.ledger.getAccountInfoByAddress(
        acceleratorAddress,
      );
      if (accountInfo.qsr()! > BigInt.zero ||
          accountInfo.znn()! > BigInt.zero) {
        addEvent(accountInfo);
      } else {
        throw 'Accelerator fund empty';
      }
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
