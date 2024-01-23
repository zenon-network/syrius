import 'dart:convert';
import 'dart:io';

import 'package:hex/hex.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:path/path.dart' as path;

abstract class WalletFile {
  final String _path;

  static Future<List<int>> read(String walletPath, String password) async {
    final file = File(walletPath);
    if (!file.existsSync()) {
      throw InvalidWalletPath('Given wallet path does not exist ($walletPath)');
    }
    return EncryptedFile.fromJson(json.decode(file.readAsStringSync()))
        .decrypt(password);
  }

  static Future<void> write(
      String walletPath, String password, List<int> data) async {
    final file = File(walletPath);
    final encrypted = await EncryptedFile.encrypt(data, password);
    file.writeAsString(json.encode(encrypted), mode: FileMode.writeOnly);
  }

  WalletFile(this._path);

  String get walletPath => _path;

  String get walletType;

  Future<Wallet> open();

  Future<void> dispose();

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    var decrypted = await WalletFile.read(walletPath, currentPassword);
    await WalletFile.write(walletPath, newPassword, decrypted);
  }
}

class KeyStoreWalletFile extends WalletFile {
  final String walletSeed;

  static final KeyStoreManager keyStoreWalletManager =
      KeyStoreManager(walletPath: znnDefaultWalletDirectory);
  static KeyStore? _keyStore;

  static Future<KeyStoreWalletFile> create(String mnemonic, String password,
      {String? name}) async {
    KeyStore wallet = KeyStore.fromMnemonic(mnemonic);
    KeyStoreDefinition walletDefinition =
        await keyStoreWalletManager.saveKeyStore(wallet, password, name: name);
    return KeyStoreWalletFile._internal(
        walletDefinition.walletId, wallet.entropy);
  }

  static Future<KeyStoreWalletFile> decrypt(
      String walletPath, String password) async {
    List<int> decrypted = await WalletFile.read(walletPath, password);
    return KeyStoreWalletFile._internal(walletPath, HEX.encode(decrypted));
  }

  KeyStoreWalletFile._internal(super.walletPath, this.walletSeed);

  KeyStore openSync() {
    _keyStore ??= KeyStore.fromEntropy(walletSeed);
    return _keyStore!;
  }

  @override
  String get walletType => kKeyStoreWalletType;

  @override
  Future<Wallet> open() async {
    return openSync();
  }

  @override
  Future<void> dispose() async {
    _keyStore = null;
  }
}

class LedgerWalletFile extends WalletFile {
  final String walletId;

  static final LedgerWalletManager ledgerWalletManager = LedgerWalletManager();
  static LedgerWallet? _wallet;

  static Future<LedgerWallet> _connect(String walletId) async {
    for (var walletDefinition
        in await ledgerWalletManager.getWalletDefinitions()) {
      if (walletDefinition.walletId == walletId) {
        return await ledgerWalletManager.getWallet(walletDefinition)
            as LedgerWallet;
      }
    }
    throw const LedgerError.connectionError(
        origMessage:
            'Cannot find the hardware device, please connect the device on which the wallet is initialized');
  }

  static Future<void> _close() async {
    if (_wallet != null) {
      try {
        await _wallet!.disconnect();
      } catch (_) {
      } finally {
        _wallet = null;
      }
    }
  }

  static Future<LedgerWalletFile> create(String walletId, String password,
      {String? name}) async {
    LedgerWallet wallet = await _connect(walletId);
    try {
      name ??= (await (await wallet.getAccount()).getAddress()).toString();
      final walletPath = path.join(znnDefaultWalletDirectory.path, name);
      await WalletFile.write(walletPath, password, utf8.encode(walletId));
      return LedgerWalletFile._internal(walletPath, walletId);
    } finally {
      await wallet.disconnect();
    }
  }

  static Future<LedgerWalletFile> decrypt(
      String walletPath, String password) async {
    List<int> decrypted = await WalletFile.read(walletPath, password);
    return LedgerWalletFile._internal(walletPath, utf8.decode(decrypted));
  }

  LedgerWalletFile._internal(super.walletPath, this.walletId);

  @override
  String get walletType => kLedgerWalletType;

  @override
  Future<Wallet> open() async {
    await _close();
    _wallet = await _connect(walletId);
    return _wallet!;
  }

  @override
  Future<void> dispose() async {
    await _close();
  }
}
