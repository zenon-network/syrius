import 'dart:async';
import 'dart:convert';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class KeyStoreFileBloc extends BaseBloc<KeyStoreWalletFile?> {
  Future<void> getKeyStorePath(
    String mnemonic,
    String password,
  ) async {
    try {
      await WalletUtils.createKeyStoreWalletFile(mnemonic, password);
      await InitUtils.initWalletAfterDecryption(
          Crypto.digest(utf8.encode(password)),);
      addEvent(kWalletFile! as KeyStoreWalletFile);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
