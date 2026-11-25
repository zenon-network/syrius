import 'dart:async';
import 'dart:convert';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class LedgerWalletFileBloc extends BaseBloc<LedgerWalletFile?> {
  Future<void> getLedgerWalletPath(String walletId, String password,
      String? walletName,) async {
    try {
      await WalletUtils.createLedgerWalletFile(walletId, password,
          walletName: walletName,);
      await InitUtils.initWalletAfterDecryption(
          Crypto.digest(utf8.encode(password)),);
      addEvent(kWalletFile! as LedgerWalletFile);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
