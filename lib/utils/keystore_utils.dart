import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class KeyStoreUtils {
  static Future<KeyStore> decryptKeyStoreFile(
    String keyStorePath,
    String password,
  ) async {
    return await KeyFile.fromJson(
      json.decode(
        File(keyStorePath).readAsStringSync(),
      ),
    ).decrypt(password);
  }

  static void _initKeyStoreConstants(
    KeyStore keyStore,
    String keyStorePath,
  ) {
    kKeyStorePath = keyStorePath;
    kWallet = keyStore;
  }

  static Future<void> createKeyStore(
    String mnemonic,
    String passphrase, {
    String? keyStoreName,
  }) async {
    KeyStoreManager keyStoreManager =
        KeyStoreManager(walletPath: znnDefaultWalletDirectory);
    KeyStore keyStore = KeyStore.fromMnemonic(mnemonic);
    KeyStoreDefinition keyStoreFile = await keyStoreManager.saveKeyStore(
      keyStore,
      passphrase,
      name: keyStoreName,
    );
    _initKeyStoreConstants(
      keyStore,
      keyStoreFile.file.path,
    );
    await _saveKeyStorePath(keyStoreFile.file.path);
  }

  static Future<void> _saveKeyStorePath(String? keyStorePath) async {
    Box keyStoreBox = await Hive.openBox(kKeyStoreBox);
    await keyStoreBox.put(0, keyStorePath);
  }

  static Future<void> setKeyStorePath() async {
    if (kKeyStorePath == null) {
      Box keyStoreBox = await Hive.openBox(kKeyStoreBox);
      if (keyStoreBox.isEmpty) {
        // Here we check if the key store path is saved in another place
        // and we copy that value, if it exists
        String? keyStorePath = sharedPrefsService!.get(kEntropyFilePathKey);
        if (keyStorePath != null) {
          keyStoreBox.add(keyStorePath);
          kKeyStorePath = keyStoreBox.values.first;
        }
      } else {
        kKeyStorePath = keyStoreBox.values.first;
      }
    } else {
      _saveKeyStorePath(kKeyStorePath);
    }
  }
}
