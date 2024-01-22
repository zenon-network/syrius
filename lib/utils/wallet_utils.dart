import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletUtils {
  static Future<Address> baseAddress() async {
    return Address.parse(kDefaultAddressList.first!);
  }

  static Future<Address> defaultAddress() async {
    return Address.parse(kSelectedAddress!);
  }

  static Future<WalletAccount> defaultAccount() async {
    return await kWalletFile!
        .account(kDefaultAddressList.indexOf(kSelectedAddress));
  }

  static Future<List<int>> defaultPublicKey() async {
    final walletAccount = await defaultAccount();
    return await walletAccount.getPublicKey();
  }

  static Future<WalletFile> decryptWalletFile(
      String walletType, String walletPath, String password) async {
    if (walletType == kKeyStoreWalletType) {
      return await KeyStoreWalletFile.decrypt(walletPath, password);
    } else if (walletType == kLedgerWalletType) {
      return await LedgerWalletFile.decrypt(walletPath, password);
    } else {
      throw UnsupportedError(
          'The specified wallet type $walletType is not supported.');
    }
  }

  static Future<void> createLedgerWalletFile(
    String walletId,
    String password, {
    String? name,
  }) async {
    kWalletFile = await LedgerWalletFile.create(walletId, password, name: name);
    kWalletPath = kWalletFile!.walletPath;
    kWalletType = kWalletFile!.walletType;
    await _storeWalletPath(kWalletFile!.walletPath);
    await _storeWalletType(kWalletFile!.walletType);
  }

  static Future<void> createKeyStoreWalletFile(
    String mnemonic,
    String password, {
    String? name,
  }) async {
    kWalletFile =
        await KeyStoreWalletFile.create(mnemonic, password, name: name);
    kWalletPath = kWalletFile!.walletPath;
    kWalletType = kWalletFile!.walletType;
    await _storeWalletPath(kWalletFile!.walletPath);
    await _storeWalletType(kWalletFile!.walletType);
  }

  static Future<void> _storeWalletPath(String? walletPath) async {
    Box keyStoreBox = await Hive.openBox(kKeyStoreBox);
    await keyStoreBox.put(0, walletPath);
  }

  static Future<void> _storeWalletType(String? walletType) async {
    Box keyStoreBox = await Hive.openBox(kKeyStoreBox);
    await keyStoreBox.put(1, walletType);
  }

  static Future<void> setWalletPathAndType() async {
    if (kWalletPath == null) {
      Box keyStoreBox = await Hive.openBox(kKeyStoreBox);
      if (keyStoreBox.isEmpty) {
        // Here we check if the key store path is saved in another place
        // and we copy that value, if it exists
        String? keyStorePath = sharedPrefsService!.get(kEntropyFilePathKey);
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

    if (kWalletType == null) {
      Box keyStoreBox = await Hive.openBox(kKeyStoreBox);
      if (keyStoreBox.values.length > 1) {
        kWalletType = keyStoreBox.getAt(1);
      } else {
        kWalletType = null;
      }
    } else {
      _storeWalletType(kWalletType);
    }
  }
}
