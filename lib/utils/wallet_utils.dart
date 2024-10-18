import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletUtils {
  static Address get baseAddress {
    return Address.parse(kDefaultAddressList.first!);
  }

  static Future<WalletFile> decryptWalletFile(
      String walletPath, String password,) async {
    return WalletFile.decrypt(walletPath, password);
  }

  static Future<void> createLedgerWalletFile(
    String walletId,
    String password, {
    String? walletName,
  }) async {
    kWalletFile = await LedgerWalletFile.create(walletId, password,
        walletName: walletName,);
    kWalletPath = kWalletFile!.walletPath;
    await _storeWalletPath(kWalletFile!.walletPath);
  }

  static Future<void> createKeyStoreWalletFile(
    String mnemonic,
    String password, {
    String? name,
  }) async {
    kWalletFile =
        await KeyStoreWalletFile.create(mnemonic, password, name: name);
    kWalletPath = kWalletFile!.walletPath;
    await _storeWalletPath(kWalletFile!.walletPath);
  }

  static Future<void> _storeWalletPath(String? walletPath) async {
    final keyStoreBox = await Hive.openBox(kKeyStoreBox);
    await keyStoreBox.put(0, walletPath);
  }

  static Future<void> setWalletPath() async {
    if (kWalletPath == null) {
      final keyStoreBox = await Hive.openBox(kKeyStoreBox);
      if (keyStoreBox.isEmpty) {
        // Here we check if the key store path is saved in another place
        // and we copy that value, if it exists
        final String? keyStorePath = sharedPrefsService!.get(kEntropyFilePathKey);
        if (keyStorePath != null) {
          keyStoreBox.add(keyStorePath);
          kWalletPath = keyStoreBox.values.first;
        }
      } else {
        kWalletPath = keyStoreBox.values.first;
      }
    } else {
      _storeWalletPath(kWalletPath);
    }
  }
}
