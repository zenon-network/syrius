import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hex/hex.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Classifies failures raised while reading or validating a wallet file.
enum WalletFileReadFailureReason {
  /// The requested wallet path does not exist on disk.
  notFound,

  /// The requested wallet path points to a directory, FIFO, or other non-file.
  notRegularFile,

  /// The wallet file exceeds [WalletFile.maxWalletFileSizeBytes].
  fileTooLarge,

  /// The encrypted file's wallet type metadata is unsupported.
  unsupportedWalletType,
}

/// A typed [WalletException] thrown by [WalletFile.read] and wallet decryptors
/// so callers can classify and localize file errors cleanly.
class WalletFileReadException extends WalletException {
  /// Creates a [WalletFileReadException] with a structured [reason] and
  /// diagnostic [message].
  WalletFileReadException(
    this.reason,
    super.message, {
    this.walletPath,
    this.maxSizeBytes,
    this.walletType,
  });

  /// Machine-readable reason describing why reading the wallet file failed.
  final WalletFileReadFailureReason reason;

  /// The filesystem path that triggered this failure, if available.
  final String? walletPath;

  /// Maximum allowed file size in bytes when [reason] is
  /// [WalletFileReadFailureReason.fileTooLarge].
  final int? maxSizeBytes;

  /// Unsupported wallet type metadata value when [reason] is
  /// [WalletFileReadFailureReason.unsupportedWalletType].
  final Object? walletType;
}

abstract class WalletFile {
  WalletFile(this._path);
  final String _path;
  static int _tmpFileCounter = 0;

  /// Keystore files are a few KB; anything far larger is a mistaken
  /// drop/pick and would freeze the UI thread in readAsStringSync.
  static const int maxWalletFileSizeBytes = 1024 * 1024;

  static Future<WalletFile> decrypt(String walletPath, String password) async {
    final EncryptedFile encrypted = await WalletFile.read(walletPath);
    final walletType = encrypted.metadata != null
        ? encrypted.metadata![walletTypeKey]
        : null;
    if (walletType == null || walletType == keyStoreWalletType) {
      return KeyStoreWalletFile.decrypt(walletPath, password);
    } else if (walletType == ledgerWalletType) {
      return LedgerWalletFile.decrypt(walletPath, password);
    } else {
      throw WalletFileReadException(
        WalletFileReadFailureReason.unsupportedWalletType,
        'Wallet type (${encrypted.metadata![walletTypeKey]}) is not supported',
        walletPath: walletPath,
        walletType: encrypted.metadata![walletTypeKey],
      );
    }
  }

  static Future<EncryptedFile> read(String walletPath) async {
    final FileSystemEntityType entityType = FileSystemEntity.typeSync(
      walletPath,
    );
    if (entityType == FileSystemEntityType.notFound) {
      throw WalletFileReadException(
        WalletFileReadFailureReason.notFound,
        'Given wallet path does not exist ($walletPath)',
        walletPath: walletPath,
      );
    }
    if (entityType != FileSystemEntityType.file) {
      throw WalletFileReadException(
        WalletFileReadFailureReason.notRegularFile,
        'Given wallet path is not a regular file ($walletPath)',
        walletPath: walletPath,
      );
    }
    final File file = File(walletPath);
    // Bound the read through a single open handle: a file swapped for a
    // larger one between a length check and the read must still be
    // caught before decoding, and the allocation is capped at
    // maxWalletFileSizeBytes + 1.
    final RandomAccessFile reader = file.openSync();
    final Uint8List bytes;
    try {
      // readSync may return fewer bytes than requested without being at
      // EOF, so accumulate from the same handle until EOF or until the
      // bound is exceeded.
      final BytesBuilder builder = BytesBuilder();
      int total = 0;
      while (total <= maxWalletFileSizeBytes) {
        final Uint8List chunk = reader.readSync(
          maxWalletFileSizeBytes + 1 - total,
        );
        if (chunk.isEmpty) {
          break;
        }
        builder.add(chunk);
        total += chunk.length;
      }
      bytes = builder.toBytes();
    } finally {
      reader.closeSync();
    }
    if (bytes.length > maxWalletFileSizeBytes) {
      throw WalletFileReadException(
        WalletFileReadFailureReason.fileTooLarge,
        'Wallet file is too large (over $maxWalletFileSizeBytes bytes) — '
        'is this a keystore file?',
        walletPath: walletPath,
        maxSizeBytes: maxWalletFileSizeBytes,
      );
    }
    final Object? decoded = json.decode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid keystore file format');
    }
    _validateEncryptedFileJson(decoded);
    try {
      return EncryptedFile.fromJson(decoded);
    } on FormatException {
      throw const FormatException('Invalid keystore file format');
    }
  }

  static void _validateEncryptedFileJson(Map<String, dynamic> jsonMap) {
    if (jsonMap['timestamp'] is! int? || jsonMap['version'] is! int?) {
      throw const FormatException('Invalid keystore file format');
    }
    final Object? crypto = jsonMap['crypto'];
    if (crypto is! Map<String, dynamic>) {
      throw const FormatException('Invalid keystore file format');
    }
    final Object? argon2Params = crypto['argon2Params'];
    if (argon2Params is! Map<String, dynamic>) {
      throw const FormatException('Invalid keystore file format');
    }
    final Object? cipherName = crypto['cipherName'];
    final Object? kdf = crypto['kdf'];
    if (!_isValidPrefixedHex(argon2Params['salt'], minBytes: 8) ||
        !_isValidPrefixedHex(crypto['cipherData'], minBytes: 16) ||
        !_isValidPrefixedHex(crypto['nonce'], minBytes: 12) ||
        cipherName is! String ||
        cipherName.isEmpty ||
        kdf is! String ||
        kdf.isEmpty) {
      throw const FormatException('Invalid keystore file format');
    }
  }

  static bool _isValidPrefixedHex(Object? value, {required int minBytes}) {
    if (value is! String || value.length < 2 + minBytes * 2) {
      return false;
    }
    if (!value.startsWith('0x') && !value.startsWith('0X')) {
      return false;
    }
    final String hexBody = value.substring(2);
    if (hexBody.length.isOdd) {
      return false;
    }
    try {
      return HEX.decode(hexBody).length >= minBytes;
    } on FormatException {
      return false;
    }
  }

  static Future<void> write(
    String walletPath,
    String password,
    List<int> data, {
    Map<String, dynamic>? metadata,
  }) async {
    final EncryptedFile encrypted = await EncryptedFile.encrypt(
      data,
      password,
      metadata: metadata,
    );
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    final File tmpFile = File(
      '$walletPath.tmp.$pid.$timestamp.${_tmpFileCounter++}',
    );
    try {
      await tmpFile.writeAsString(json.encode(encrypted), flush: true);
      await tmpFile.rename(walletPath);
    } on Object catch (_) {
      try {
        if (tmpFile.existsSync()) {
          await tmpFile.delete();
        }
      } on FileSystemException catch (_) {
        // Ignore cleanup errors so the original error propagates.
      }
      rethrow;
    }
  }

  String get walletPath => _path;

  String get walletType;

  bool get isOpen;

  /// Whether this wallet file has been permanently closed.
  bool get isClosed => false;

  bool get isHardwareWallet;

  /// Runs [accessSection] while holding exclusive access to this wallet.
  Future<T> access<T>(Future<T> Function(Wallet) accessSection);

  /// Permanently closes this wallet file without releasing another operation's
  /// active access lock.
  Future<void> close();

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final EncryptedFile file = await WalletFile.read(walletPath);
    final List<int> decrypted = await file.decrypt(currentPassword);
    await WalletFile.write(
      walletPath,
      newPassword,
      decrypted,
      metadata: file.metadata,
    );
  }
}

class _WalletFileLifecycle {
  final Mutex _lock = Mutex();
  bool _isClosed = false;
  bool _isSessionActive = false;
  Future<void>? _closeFuture;

  bool get isOpen => _isSessionActive;

  bool get isClosed => _isClosed;

  Future<T> access<T>({
    required Future<Wallet> Function() openSession,
    required Future<void> Function({required bool isClosing}) closeSession,
    required Future<T> Function(Wallet) accessSection,
  }) async {
    if (_isClosed) {
      throw WalletException('Wallet file is closed');
    }
    return await _lock.protect<T>(() async {
      if (_isClosed) {
        throw WalletException('Wallet file is closed');
      }
      _isSessionActive = true;
      try {
        final Wallet wallet = await openSession();
        try {
          if (_isClosed) {
            throw WalletException('Wallet file is closed');
          }
          return await accessSection(wallet);
        } finally {
          await closeSession(isClosing: _isClosed);
        }
      } finally {
        _isSessionActive = false;
      }
    });
  }

  Future<void> close({required Future<void> Function() dispose}) {
    _isClosed = true;
    return _closeFuture ??= _lock.protect<void>(dispose);
  }
}

class KeyStoreWalletFile extends WalletFile {
  KeyStoreWalletFile._internal(super._path, String walletSeed)
    : _walletSeed = walletSeed;
  final _WalletFileLifecycle _lifecycle = _WalletFileLifecycle();
  String? _walletSeed;
  KeyStore? _keyStore;

  static final KeyStoreManager keyStoreWalletManager = KeyStoreManager(
    walletPath: znnDefaultWalletDirectory,
  );

  static Future<KeyStoreWalletFile> create(
    String mnemonic,
    String password, {
    String? name,
  }) async {
    final KeyStore wallet = KeyStore.fromMnemonic(mnemonic);
    final KeyStoreDefinition walletDefinition = await keyStoreWalletManager
        .saveKeyStore(wallet, password, name: name);
    return KeyStoreWalletFile._internal(
      walletDefinition.walletId,
      wallet.entropy,
    );
  }

  static Future<KeyStoreWalletFile> decrypt(
    String walletPath,
    String password,
  ) async {
    final EncryptedFile encrypted = await WalletFile.read(walletPath);
    if (encrypted.metadata != null &&
        encrypted.metadata![walletTypeKey] != null &&
        encrypted.metadata![walletTypeKey] != keyStoreWalletType) {
      throw WalletFileReadException(
        WalletFileReadFailureReason.unsupportedWalletType,
        'Wallet type (${encrypted.metadata![walletTypeKey]}) is not supported',
        walletPath: walletPath,
        walletType: encrypted.metadata![walletTypeKey],
      );
    }
    final List<int> decrypted = await encrypted.decrypt(password);
    return KeyStoreWalletFile._internal(walletPath, HEX.encode(decrypted));
  }

  @override
  String get walletType => keyStoreWalletType;

  @override
  bool get isOpen => _lifecycle.isOpen;

  @override
  bool get isClosed => _lifecycle.isClosed;

  @override
  bool get isHardwareWallet => false;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) {
    return _lifecycle.access<T>(
      openSession: _openSession,
      closeSession: _closeSession,
      accessSection: accessSection,
    );
  }

  Future<Wallet> _openSession() async {
    final String? seed = _walletSeed;
    if (seed == null) {
      throw WalletException('Wallet file is closed');
    }
    _keyStore ??= KeyStore.fromEntropy(seed);
    return _keyStore!;
  }

  Future<void> _closeSession({required bool isClosing}) async {
    if (isClosing) {
      _clearMemory();
    }
  }

  void _clearMemory() {
    _keyStore = null;
    _walletSeed = null;
  }

  @override
  Future<void> close() {
    return _lifecycle.close(
      dispose: () async {
        _clearMemory();
      },
    );
  }
}

class LedgerWalletFile extends WalletFile {
  LedgerWalletFile._internal(super._path, this._walletName)
    : _connector = _connect;

  /// Creates a [LedgerWalletFile] with a custom device connector for tests.
  @visibleForTesting
  LedgerWalletFile.forTesting(super._path, this._walletName, this._connector);

  final _WalletFileLifecycle _lifecycle = _WalletFileLifecycle();
  final String _walletName;
  final Future<LedgerWallet> Function(String walletIdOrName) _connector;
  LedgerWallet? _wallet;

  static final LedgerWalletManager ledgerWalletManager = LedgerWalletManager();

  static Future<LedgerWallet> _connect(String walletIdOrName) async {
    for (final WalletDefinition walletDefinition
        in await ledgerWalletManager.getWalletDefinitions()) {
      if (walletDefinition.walletId == walletIdOrName ||
          walletDefinition.walletName == walletIdOrName) {
        return await ledgerWalletManager.getWallet(walletDefinition)
            as LedgerWallet;
      }
    }
    throw const LedgerError.connectionError(
      origMessage:
          'Cannot find the hardware device, please connect/unlock the device on which the wallet is initialized',
    );
  }

  static Future<LedgerWalletFile> create(
    String walletId,
    String password, {
    String? walletName,
  }) async {
    final LedgerWallet wallet = await _connect(walletId);
    try {
      final Address baseAddress = await (await wallet.getAccount())
          .getAddress();
      walletName ??= baseAddress.toString();
      final String walletPath = path.join(
        znnDefaultWalletDirectory.path,
        walletName,
      );
      await WalletFile.write(
        walletPath,
        password,
        utf8.encode(walletName),
        metadata: <String, String>{
          baseAddressKey: baseAddress.toString(),
          walletTypeKey: ledgerWalletType,
        },
      );
      return LedgerWalletFile._internal(walletPath, walletName);
    } finally {
      await wallet.disconnect();
    }
  }

  static Future<LedgerWalletFile> decrypt(
    String walletPath,
    String password,
  ) async {
    final EncryptedFile encrypted = await WalletFile.read(walletPath);
    if (encrypted.metadata == null ||
        encrypted.metadata![walletTypeKey] != ledgerWalletType) {
      throw WalletFileReadException(
        WalletFileReadFailureReason.unsupportedWalletType,
        'Wallet type (${encrypted.metadata?[walletTypeKey]}) is not supported',
        walletPath: walletPath,
        walletType: encrypted.metadata?[walletTypeKey],
      );
    }
    final List<int> decrypted = await encrypted.decrypt(password);
    return LedgerWalletFile._internal(walletPath, utf8.decode(decrypted));
  }

  @override
  String get walletType => ledgerWalletType;

  @override
  bool get isOpen => _lifecycle.isOpen;

  @override
  bool get isClosed => _lifecycle.isClosed;

  @override
  bool get isHardwareWallet => true;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) {
    return _lifecycle.access<T>(
      openSession: _openSession,
      closeSession: ({required bool isClosing}) => _disconnectWallet(),
      accessSection: accessSection,
    );
  }

  Future<Wallet> _openSession() async {
    _wallet = await _connector(_walletName);
    return _wallet!;
  }

  Future<void> _disconnectWallet() async {
    final LedgerWallet? wallet = _wallet;
    _wallet = null;
    if (wallet != null) {
      try {
        await wallet.disconnect();
      } on Object catch (_) {}
    }
  }

  @override
  Future<void> close() {
    return _lifecycle.close(dispose: _disconnectWallet);
  }
}
