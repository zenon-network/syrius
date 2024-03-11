import 'dart:convert';
import 'dart:io';

import 'package:hex/hex.dart';
import 'package:mutex/mutex.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:path/path.dart' as path;

abstract class WalletFile {
  final String _path;

  static Future<WalletFile> decrypt(String walletPath, String password) async {
    final encrypted = await WalletFile.read(walletPath);
    final walletType =
        encrypted.metadata != null ? encrypted.metadata![walletTypeKey] : null;
    if (walletType == null || walletType == keyStoreWalletType) {
      return await KeyStoreWalletFile.decrypt(walletPath, password);
    } else if (walletType == ledgerWalletType) {
      return await LedgerWalletFile.decrypt(walletPath, password);
    } else {
      throw WalletException(
          'Wallet type (${encrypted.metadata![walletTypeKey]}) is not supported');
    }
  }

  static Future<EncryptedFile> read(String walletPath) async {
    final file = File(walletPath);
    if (!file.existsSync()) {
      throw WalletException('Given wallet path does not exist ($walletPath)');
    }
    return EncryptedFile.fromJson(json.decode(file.readAsStringSync()));
  }

  static Future<void> write(String walletPath, String password, List<int> data,
      {Map<String, dynamic>? metadata}) async {
    final file = File(walletPath);
    final encrypted =
        await EncryptedFile.encrypt(data, password, metadata: metadata);
    file.writeAsString(json.encode(encrypted), mode: FileMode.writeOnly);
  }

  WalletFile(this._path);

  String get walletPath => _path;

  String get walletType;

  bool get isOpen;

  bool get isHardwareWallet;

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
    final file = await WalletFile.read(walletPath);
    final decrypted = await file.decrypt(currentPassword);
    await WalletFile.write(walletPath, newPassword, decrypted,
        metadata: file.metadata);
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
    final encrypted = await WalletFile.read(walletPath);
    if (encrypted.metadata != null &&
        encrypted.metadata![walletTypeKey] != null &&
        encrypted.metadata![walletTypeKey] != keyStoreWalletType) {
      throw WalletException(
          'Wallet type (${encrypted.metadata![walletTypeKey]}) is not supported');
    }
    final decrypted = await encrypted.decrypt(password);
    return KeyStoreWalletFile._internal(walletPath, HEX.encode(decrypted));
  }

  KeyStoreWalletFile._internal(super._path, this._walletSeed);

  @override
  String get walletType => keyStoreWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  bool get isHardwareWallet => false;

  @override
  Future<Wallet> open() async {
    await _lock.acquire();
    try {
      _keyStore ??= KeyStore.fromEntropy(_walletSeed);
      return _keyStore!;
    } catch (_) {
      _lock.release();
      rethrow;
    }
  }

  @override
  void close() async {
    if (_lock.isLocked) _lock.release();
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
      final baseAddress = (await (await wallet.getAccount()).getAddress());
      name ??= baseAddress.toString();
      final walletPath = path.join(znnDefaultWalletDirectory.path, name);
      await WalletFile.write(walletPath, password, utf8.encode(walletId),
          metadata: {
            baseAddressKey: baseAddress.toString(),
            walletTypeKey: ledgerWalletType
          });
      return LedgerWalletFile._internal(walletPath, walletId);
    } finally {
      await wallet.disconnect();
    }
  }

  static Future<LedgerWalletFile> decrypt(
      String walletPath, String password) async {
    final encrypted = await WalletFile.read(walletPath);
    if (encrypted.metadata == null ||
        encrypted.metadata![walletTypeKey] != ledgerWalletType) {
      throw WalletException(
          'Wallet type (${encrypted.metadata![walletTypeKey]}) is not supported');
    }
    final decrypted = await encrypted.decrypt(password);
    return LedgerWalletFile._internal(walletPath, utf8.decode(decrypted));
  }

  LedgerWalletFile._internal(super._path, this._walletId);

  @override
  String get walletType => ledgerWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  bool get isHardwareWallet => true;

  @override
  Future<Wallet> open() async {
    await _lock.acquire();
    try {
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
    if (_lock.isLocked) _lock.release();
  }
}
