import 'dart:convert';
import 'dart:io';

import 'package:hex/hex.dart';
import 'package:mutex/mutex.dart';
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

  bool get isOpen;

  Future<Wallet> open();

  void close();

  Future<T> access<T>(Future<T> Function(Wallet) accessSection) async {
    final wallet = await open();
    try {
      return await accessSection(wallet);
    } finally {
      close();
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    var decrypted = await WalletFile.read(walletPath, currentPassword);
    await WalletFile.write(walletPath, newPassword, decrypted);
  }
}

class KeyStoreWalletFile extends WalletFile {
  final Mutex _lock = Mutex();
  final String _walletSeed;
  KeyStore? _keyStore;

  static final KeyStoreManager keyStoreWalletManager =
      KeyStoreManager(walletPath: znnDefaultWalletDirectory);

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

  KeyStoreWalletFile._internal(super._path, this._walletSeed);

  @override
  String get walletType => kKeyStoreWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  Future<Wallet> open() async {
    await _lock.acquire();
    _keyStore ??= KeyStore.fromEntropy(_walletSeed);
    return _keyStore!;
  }

  @override
  void close() async {
    _lock.release();
  }
}

class LedgerWalletFile extends WalletFile {
  final Mutex _lock = Mutex();
  final String _walletId;
  LedgerWallet? _wallet;

  static final LedgerWalletManager ledgerWalletManager = LedgerWalletManager();

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

  LedgerWalletFile._internal(super._path, this._walletId);

  @override
  String get walletType => kLedgerWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  Future<Wallet> open() async {
    await _lock.acquire();
    try
    {
      _wallet = await _connect(_walletId);
      return _wallet!;
    } catch (_) {
      _lock.release();
      rethrow;
    }
  }

  @override
  void close() async {
    if (_wallet != null) {
      try {
        await _wallet!.disconnect();
      } catch (_) {
      } finally {
        _wallet = null;
      }
    }
    _lock.release();
  }
}
