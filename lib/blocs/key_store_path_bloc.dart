import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/keystore_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';

class KeyStorePathBloc extends BaseBloc<String?> {
  Future<void> getKeyStorePath(
    BuildContext context,
    String mnemonic,
    String passphrase,
  ) async {
    try {
      await KeyStoreUtils.createKeyStore(mnemonic, passphrase);
      await InitUtils.initWalletAfterDecryption(context);
      addEvent(kKeyStorePath);
    } catch (e) {
      addError(e);
    }
  }
}
