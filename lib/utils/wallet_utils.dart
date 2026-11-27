import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Utilities for creating, decrypting, and managing the active [WalletFile].
class WalletUtils {
  /// Returns the primary (index 0) wallet address.
  static Address get baseAddress {
    return Address.parse(kDefaultAddressList.first!);
  }

  /// Replaces the active [kWalletFile] with [nextWalletFile] and closes any
  /// distinct previously active [WalletFile].
  static Future<void> setWalletFile(WalletFile? nextWalletFile) async {
    final WalletFile? previousWalletFile = kWalletFile;
    kWalletFile = nextWalletFile;
    if (previousWalletFile != null &&
        !identical(previousWalletFile, nextWalletFile)) {
      await _safeCloseWalletFile(previousWalletFile);
    }
  }

  static Future<void> _safeCloseWalletFile(WalletFile walletFile) async {
    try {
      await walletFile.close();
    } on Object catch (error, stackTrace) {
      Logger('WalletUtils').log(
        Level.WARNING,
        'Failed to close WalletFile',
        error,
        stackTrace,
      );
    }
  }

  /// Decrypts the wallet file at [walletPath] with [password].
  static Future<WalletFile> decryptWalletFile(
    String walletPath,
    String password,
  ) => WalletFile.decrypt(walletPath, password);

  /// Creates a new [LedgerWalletFile], persists its path, and activates it.
  static Future<void> createLedgerWalletFile(
    String walletId,
    String password, {
    String? walletName,
    @visibleForTesting
    Future<LedgerWalletFile> Function(
      String walletId,
      String password, {
      String? walletName,
    })?
    createWalletFile,
    @visibleForTesting
    Future<void> Function(String? walletPath)? storeWalletPath,
  }) async {
    final LedgerWalletFile createdWalletFile =
        await (createWalletFile ?? LedgerWalletFile.create)(
          walletId,
          password,
          walletName: walletName,
        );
    try {
      await (storeWalletPath ?? _storeWalletPath)(createdWalletFile.walletPath);
    } on Object {
      await _safeCloseWalletFile(createdWalletFile);
      rethrow;
    }
    kWalletPath = createdWalletFile.walletPath;
    await setWalletFile(createdWalletFile);
  }

  /// Creates a new [KeyStoreWalletFile] from [mnemonic], persists its path,
  /// and activates it.
  static Future<void> createKeyStoreWalletFile(
    String mnemonic,
    String password, {
    String? name,
    @visibleForTesting
    Future<KeyStoreWalletFile> Function(
      String mnemonic,
      String password, {
      String? name,
    })?
    createWalletFile,
    @visibleForTesting
    Future<void> Function(String? walletPath)? storeWalletPath,
  }) async {
    final KeyStoreWalletFile createdWalletFile =
        await (createWalletFile ?? KeyStoreWalletFile.create)(
          mnemonic,
          password,
          name: name,
        );
    try {
      await (storeWalletPath ?? _storeWalletPath)(createdWalletFile.walletPath);
    } on Object {
      await _safeCloseWalletFile(createdWalletFile);
      rethrow;
    }
    kWalletPath = createdWalletFile.walletPath;
    await setWalletFile(createdWalletFile);
  }

  static Future<void> _storeWalletPath(String? walletPath) async {
    final Box<dynamic> keyStoreBox = await Hive.openBox<dynamic>(kKeyStoreBox);
    await keyStoreBox.put(0, walletPath);
  }

  /// Restores [kWalletPath] from Hive storage (migrating from legacy shared
  /// preferences if needed) or persists the current [kWalletPath].
  static Future<void> setWalletPath() async {
    if (kWalletPath == null) {
      final Box<dynamic> keyStoreBox = await Hive.openBox<dynamic>(
        kKeyStoreBox,
      );
      if (keyStoreBox.isEmpty) {
        // Here we check if the key store path is saved in another place
        // and we copy that value, if it exists
        final String? keyStorePath = sharedPrefsService!.get(
          kEntropyFilePathKey,
        );
        if (keyStorePath != null) {
          await keyStoreBox.add(keyStorePath);
          kWalletPath = keyStoreBox.values.first;
        }
      } else {
        kWalletPath = keyStoreBox.values.first;
      }
    } else {
      await _storeWalletPath(kWalletPath);
    }
  }
}
