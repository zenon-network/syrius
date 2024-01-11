import 'dart:async';
import 'dart:convert';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/keystore_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class KeyStorePathBloc extends BaseBloc<String?> {
  Future<void> getKeyStorePath(
    String mnemonic,
    String passphrase,
  ) async {
    try {
      await KeyStoreUtils.createKeyStore(mnemonic, passphrase);
      await InitUtils.initWalletAfterDecryption(
          Crypto.digest(utf8.encode(passphrase)));
      addEvent(kKeyStorePath);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
