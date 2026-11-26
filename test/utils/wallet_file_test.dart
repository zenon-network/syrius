import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _FakeLedgerWallet extends Fake implements LedgerWallet {
  int disconnectCalls = 0;

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }
}

List<FileSystemEntity> _tmpFilesIn(Directory dir) {
  return dir
      .listSync()
      .where(
        (FileSystemEntity entity) =>
            path.basename(entity.path).contains('.tmp'),
      )
      .toList();
}

Future<({KeyStore keyStore, String baseAddress, KeyStoreWalletFile walletFile})>
    _createKeyStoreWalletFile({
  required String walletPath,
  required String password,
}) async {
  final KeyStore keyStore = await KeyStore.newRandom();
  final Address baseAddress =
      await (await keyStore.getAccount()).getAddress();
  final String baseAddressStr = baseAddress.toString();

  await WalletFile.write(
    walletPath,
    password,
    HEX.decode(keyStore.entropy),
    metadata: <String, dynamic>{
      baseAddressKey: baseAddressStr,
      walletTypeKey: keyStoreWalletType,
    },
  );

  final KeyStoreWalletFile walletFile =
      await KeyStoreWalletFile.decrypt(walletPath, password);

  return (
    keyStore: keyStore,
    baseAddress: baseAddressStr,
    walletFile: walletFile,
  );
}

void main() {
  group('WalletFile.write', () {
    test(
      'atomically creates and overwrites wallet file without tmp files',
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_file_atomic_test_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final String walletPath = path.join(tempDir.path, 'wallet');
        const String initialPassword = 'initial-password-123';
        const String updatedPassword = 'updated-password-456';
        final List<int> initialData = utf8.encode('initial-wallet-secret');
        final List<int> updatedData = utf8.encode('updated-wallet-secret');
        final Map<String, dynamic> initialMetadata = <String, dynamic>{
          baseAddressKey: 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
          walletTypeKey: keyStoreWalletType,
        };
        final Map<String, dynamic> updatedMetadata = <String, dynamic>{
          baseAddressKey: 'z1qr4pexnnfaexqqz8nscjjcsajy5hdqf9vzmrv2',
          walletTypeKey: keyStoreWalletType,
        };

        await WalletFile.write(
          walletPath,
          initialPassword,
          initialData,
          metadata: initialMetadata,
        );

        final EncryptedFile firstEncrypted = await WalletFile.read(walletPath);
        expect(firstEncrypted.metadata, initialMetadata);
        expect(await firstEncrypted.decrypt(initialPassword), initialData);
        expect(_tmpFilesIn(tempDir), isEmpty);

        await WalletFile.write(
          walletPath,
          updatedPassword,
          updatedData,
          metadata: updatedMetadata,
        );

        final EncryptedFile secondEncrypted = await WalletFile.read(walletPath);
        expect(secondEncrypted.metadata, updatedMetadata);
        expect(await secondEncrypted.decrypt(updatedPassword), updatedData);
        await expectLater(
          secondEncrypted.decrypt(initialPassword),
          throwsA(isA<IncorrectPasswordException>()),
        );
        expect(_tmpFilesIn(tempDir), isEmpty);
        expect(tempDir.listSync(), hasLength(1));
      },
    );

    test(
      'propagates FileSystemException when parent directory is missing',
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_file_missing_dir_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final String missingPath =
            path.join(tempDir.path, 'does_not_exist', 'wallet');

        final List<Object> unhandledErrors = <Object>[];
        await runZonedGuarded<Future<void>>(
          () async {
            await expectLater(
              WalletFile.write(
                missingPath,
                'password-123',
                utf8.encode('wallet-secret'),
              ),
              throwsA(isA<FileSystemException>()),
            );
            // Allow pending async callbacks to run so any unawaited error
            // would be captured by the zone error handler.
            await Future<void>.delayed(const Duration(milliseconds: 50));
          },
          (Object error, StackTrace stackTrace) {
            unhandledErrors.add(error);
          },
        );

        expect(unhandledErrors, isEmpty);
        expect(File(missingPath).existsSync(), isFalse);
        expect(_tmpFilesIn(tempDir), isEmpty);
      },
    );

    test(
      'cleans up temporary file and propagates error when rename fails',
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_file_rename_fail_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final Directory targetDir = Directory(path.join(tempDir.path, 'wallet'))
          ..createSync();

        await expectLater(
          WalletFile.write(
            targetDir.path,
            'password-123',
            utf8.encode('wallet-secret'),
          ),
          throwsA(isA<FileSystemException>()),
        );

        expect(targetDir.existsSync(), isTrue);
        expect(_tmpFilesIn(tempDir), isEmpty);
        expect(tempDir.listSync(), hasLength(1));
      },
    );
  });

  group('KeyStoreWalletFile.changePassword', () {
    test(
      're-encrypts keystore and preserves mnemonic and metadata',
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_file_rekey_ok_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final String walletPath = path.join(tempDir.path, 'keystore');
        const String oldPassword = 'old-password-123';
        const String newPassword = 'new-password-456';

        final ({
          KeyStore keyStore,
          String baseAddress,
          KeyStoreWalletFile walletFile,
        }) created = await _createKeyStoreWalletFile(
          walletPath: walletPath,
          password: oldPassword,
        );

        await created.walletFile.changePassword(oldPassword, newPassword);

        await expectLater(
          KeyStoreWalletFile.decrypt(walletPath, oldPassword),
          throwsA(isA<IncorrectPasswordException>()),
        );

        final KeyStoreWalletFile rekeyedWallet =
            await KeyStoreWalletFile.decrypt(walletPath, newPassword);
        final String? rekeyedMnemonic = await rekeyedWallet.access<String?>(
          (Wallet wallet) async => (wallet as KeyStore).mnemonic,
        );
        expect(rekeyedMnemonic, created.keyStore.mnemonic);

        final EncryptedFile encrypted = await WalletFile.read(walletPath);
        expect(encrypted.metadata, <String, dynamic>{
          baseAddressKey: created.baseAddress,
          walletTypeKey: keyStoreWalletType,
        });
        expect(_tmpFilesIn(tempDir), isEmpty);
      },
    );

    test(
      'leaves original keystore intact when directory is read-only',
      skip: Platform.isWindows ? 'POSIX directory permissions required' : false,
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_file_rekey_ro_');
        addTearDown(() {
          Process.runSync('chmod', <String>['0755', tempDir.path]);
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final String walletPath = path.join(tempDir.path, 'keystore');
        const String oldPassword = 'old-password-123';
        const String newPassword = 'new-password-456';

        final ({
          KeyStore keyStore,
          String baseAddress,
          KeyStoreWalletFile walletFile,
        }) created = await _createKeyStoreWalletFile(
          walletPath: walletPath,
          password: oldPassword,
        );

        final List<int> originalBytes = File(walletPath).readAsBytesSync();

        final ProcessResult lockResult =
            Process.runSync('chmod', <String>['0555', tempDir.path]);
        expect(lockResult.exitCode, 0);

        final File probeFile = File(path.join(tempDir.path, '.write_probe'));
        bool canWriteInReadOnlyDir = false;
        try {
          probeFile.writeAsStringSync('probe');
          canWriteInReadOnlyDir = true;
        } on FileSystemException {
          canWriteInReadOnlyDir = false;
        } finally {
          if (probeFile.existsSync()) {
            probeFile.deleteSync();
          }
        }

        if (canWriteInReadOnlyDir) {
          markTestSkipped(
            'Process can write inside 0555 directories (e.g. root user)',
          );
          return;
        }

        await expectLater(
          created.walletFile.changePassword(oldPassword, newPassword),
          throwsA(isA<FileSystemException>()),
        );

        final ProcessResult unlockResult =
            Process.runSync('chmod', <String>['0755', tempDir.path]);
        expect(unlockResult.exitCode, 0);

        expect(File(walletPath).readAsBytesSync(), originalBytes);

        final KeyStoreWalletFile intactWallet =
            await KeyStoreWalletFile.decrypt(walletPath, oldPassword);
        final String? intactMnemonic = await intactWallet.access<String?>(
          (Wallet wallet) async => (wallet as KeyStore).mnemonic,
        );
        expect(intactMnemonic, created.keyStore.mnemonic);

        await expectLater(
          KeyStoreWalletFile.decrypt(walletPath, newPassword),
          throwsA(isA<IncorrectPasswordException>()),
        );
        expect(_tmpFilesIn(tempDir), isEmpty);
      },
    );
  });

  group('WalletFile.read validation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('wallet_file_read_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'rejects a directory with a clear non-regular file WalletException',
      () async {
        final Directory subDir = Directory(path.join(tempDir.path, 'a_dir'))
          ..createSync();

        await expectLater(
          () => WalletFile.read(subDir.path),
          throwsA(
            isA<WalletException>().having(
              (WalletException e) => e.message,
              'message',
              contains('not a regular file'),
            ),
          ),
        );
      },
    );

    test(
      'rejects a symlink to a directory with a non-regular file error',
      skip: Platform.isWindows ? 'POSIX symlinks required' : false,
      () async {
        final Directory subDir = Directory(path.join(tempDir.path, 'dir_tgt'))
          ..createSync();
        final Link link = Link(path.join(tempDir.path, 'dir_link'))
          ..createSync(subDir.path);

        await expectLater(
          () => WalletFile.read(link.path),
          throwsA(
            isA<WalletException>().having(
              (WalletException e) => e.message,
              'message',
              contains('not a regular file'),
            ),
          ),
        );
      },
    );

    test(
      'rejects a named pipe (FIFO) without blocking',
      skip: Platform.isWindows ? 'POSIX mkfifo required' : false,
      () async {
        final String fifoPath = path.join(tempDir.path, 'wallet.fifo');
        final ProcessResult result = Process.runSync('mkfifo', <String>[
          fifoPath,
        ]);
        expect(result.exitCode, 0);

        await expectLater(
          () => WalletFile.read(fifoPath).timeout(const Duration(seconds: 2)),
          throwsA(
            isA<WalletException>().having(
              (WalletException e) => e.message,
              'message',
              contains('not a regular file'),
            ),
          ),
        );
      },
    );

    test(
      'reads a symlink pointing to a valid regular keystore file',
      skip: Platform.isWindows ? 'POSIX symlinks required' : false,
      () async {
        final String walletPath = path.join(tempDir.path, 'real_wallet');
        final String linkPath = path.join(tempDir.path, 'linked_wallet');
        await WalletFile.write(
          walletPath,
          'SecretPass123!',
          utf8.encode('symlink-payload'),
        );
        Link(linkPath).createSync(walletPath);

        final EncryptedFile loaded = await WalletFile.read(linkPath);
        expect(
          utf8.decode(await loaded.decrypt('SecretPass123!')),
          'symlink-payload',
        );
      },
    );

    test(
      'rejects JSON objects missing required keystore fields with '
      'FormatException instead of TypeError',
      () async {
        final String saltHex = '0x${'aa' * 16}';
        final String cipherHex = '0x${'aa' * 16}';
        final String nonceHex = '0x${'bb' * 12}';
        final Map<String, String> invalidPayloads = <String, String>{
          'empty_object.json': '{}',
          'null_crypto.json': '{"crypto": null}',
          'non_map_crypto.json': '{"crypto": "invalid"}',
          'empty_crypto.json': '{"crypto": {}}',
          'missing_argon2.json':
              '{"crypto": {"cipherData": "$cipherHex", '
              '"nonce": "$nonceHex", "cipherName": "aes-256-gcm", '
              '"kdf": "argon2.IDKey"}}',
          'missing_salt.json':
              '{"crypto": {"argon2Params": {}, "cipherData": "$cipherHex", '
              '"nonce": "$nonceHex", "cipherName": "aes-256-gcm", '
              '"kdf": "argon2.IDKey"}}',
          'bad_hex_salt.json':
              '{"crypto": {"argon2Params": {"salt": "0xzzzz"}, '
              '"cipherData": "$cipherHex", "nonce": "$nonceHex", '
              '"cipherName": "aes-256-gcm", "kdf": "argon2.IDKey"}}',
          'unprefixed_hex.json':
              '{"crypto": {"argon2Params": {"salt": "${'aa' * 16}"}, '
              '"cipherData": "$cipherHex", "nonce": "$nonceHex", '
              '"cipherName": "aes-256-gcm", "kdf": "argon2.IDKey"}}',
          'short_cipher_data.json':
              '{"crypto": {"argon2Params": {"salt": "$saltHex"}, '
              '"cipherData": "0x0102", "nonce": "$nonceHex", '
              '"cipherName": "aes-256-gcm", "kdf": "argon2.IDKey"}}',
          'short_salt.json':
              '{"crypto": {"argon2Params": {"salt": "0x01020304"}, '
              '"cipherData": "$cipherHex", "nonce": "$nonceHex", '
              '"cipherName": "aes-256-gcm", "kdf": "argon2.IDKey"}}',
          'short_nonce.json':
              '{"crypto": {"argon2Params": {"salt": "$saltHex"}, '
              '"cipherData": "$cipherHex", "nonce": "0x01020304", '
              '"cipherName": "aes-256-gcm", "kdf": "argon2.IDKey"}}',
          'bad_version_type.json':
              '{"version": "1", "crypto": {"argon2Params": '
              '{"salt": "$saltHex"}, "cipherData": "$cipherHex", '
              '"nonce": "$nonceHex", "cipherName": "aes-256-gcm", '
              '"kdf": "argon2.IDKey"}}',
        };

        for (final MapEntry<String, String> entry in invalidPayloads.entries) {
          final File file = File(path.join(tempDir.path, entry.key))
            ..writeAsStringSync(entry.value);
          await expectLater(
            () => WalletFile.read(file.path),
            throwsA(isA<FormatException>()),
            reason: 'Expected FormatException for ${entry.key}',
          );
        }
      },
    );

    test(
      'accepts keystore JSON at exact minimum salt (8B), nonce (12B), and '
      'cipherData (16B) boundaries',
      () async {
        final File minValid = File(path.join(tempDir.path, 'min_valid.json'))
          ..writeAsStringSync(
            '{"crypto": {"argon2Params": {"salt": "0x${'11' * 8}"}, '
            '"cipherData": "0x${'22' * 16}", '
            '"nonce": "0x${'33' * 12}", '
            '"cipherName": "aes-256-gcm", '
            '"kdf": "argon2.IDKey"}}',
          );

        final EncryptedFile loaded = await WalletFile.read(minValid.path);
        expect(loaded.crypto, isNotNull);
      },
    );

    test(
      'WalletFile.decrypt surfaces FormatException for empty JSON object',
      () async {
        final File emptyJson = File(path.join(tempDir.path, 'empty.json'))
          ..writeAsStringSync('{}');

        await expectLater(
          () => WalletFile.decrypt(emptyJson.path, 'any-password'),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('WalletFile.close concurrency safety', () {
    test(
      'KeyStoreWalletFile.close does not prematurely release mutex held by '
      'in-flight access and rejects queued/subsequent accesses',
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_file_close_ks_');
        addTearDown(() {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final ({
          KeyStore keyStore,
          String baseAddress,
          KeyStoreWalletFile walletFile,
        }) created = await _createKeyStoreWalletFile(
          walletPath: path.join(tempDir.path, 'keystore'),
          password: 'password-123',
        );
        final KeyStoreWalletFile walletFile = created.walletFile;

        final Completer<void> firstEntered = Completer<void>();
        final Completer<void> releaseFirst = Completer<void>();
        bool secondEntered = false;
        bool closeCompleted = false;

        final Future<String?> firstAccess = walletFile.access<String?>(
          (Wallet wallet) async {
            firstEntered.complete();
            await releaseFirst.future;
            return (wallet as KeyStore).mnemonic;
          },
        );
        await firstEntered.future;
        expect(walletFile.isOpen, isTrue);
        expect(walletFile.isClosed, isFalse);

        // Queue a second operation while the first holds the mutex.
        final Future<void> queuedAccess = walletFile.access<void>((_) async {
          secondEntered = true;
        });
        final Future<void> queuedRejection = expectLater(
          queuedAccess,
          throwsA(
            isA<WalletException>().having(
              (WalletException e) => e.message,
              'message',
              contains('closed'),
            ),
          ),
        );

        // Simulate concurrent wallet lock/reset calling close().
        final Future<void> closeFuture = walletFile.close().then((_) {
          closeCompleted = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // close() must mark the wallet closed, wait for the in-flight access,
        // and NOT release the mutex to the queued operation.
        expect(walletFile.isClosed, isTrue);
        expect(walletFile.isOpen, isTrue);
        expect(secondEntered, isFalse);
        expect(closeCompleted, isFalse);

        // Any new access after close() fails immediately without entering.
        await expectLater(
          walletFile.access<void>((_) async {
            fail('accessSection should not run on a closed wallet');
          }),
          throwsA(isA<WalletException>()),
        );

        // Completing the in-flight access releases its own mutex; queued access
        // is rejected and close() completes cleanly.
        releaseFirst.complete();
        expect(await firstAccess, created.keyStore.mnemonic);
        await queuedRejection;
        await closeFuture;

        expect(secondEntered, isFalse);
        expect(closeCompleted, isTrue);
        expect(walletFile.isOpen, isFalse);
        expect(walletFile.isClosed, isTrue);

        // Repeated close() calls are idempotent.
        await walletFile.close();
      },
    );

    test(
      'LedgerWalletFile.close waits for in-flight access before tearing down '
      'and does not release mutex or disconnect active USB session early',
      () async {
        int connectCalls = 0;
        final List<_FakeLedgerWallet> createdWallets = <_FakeLedgerWallet>[];

        final LedgerWalletFile walletFile = LedgerWalletFile.forTesting(
          '/tmp/fake-ledger',
          'ledger-device-1',
          (_) async {
            connectCalls += 1;
            final _FakeLedgerWallet fakeWallet = _FakeLedgerWallet();
            createdWallets.add(fakeWallet);
            return fakeWallet;
          },
        );

        final Completer<void> firstEntered = Completer<void>();
        final Completer<void> releaseFirst = Completer<void>();
        bool secondEntered = false;
        bool closeCompleted = false;

        final Future<String> firstAccess = walletFile.access<String>(
          (Wallet wallet) async {
            firstEntered.complete();
            await releaseFirst.future;
            return 'signed';
          },
        );
        await firstEntered.future;
        expect(connectCalls, 1);
        expect(createdWallets.single.disconnectCalls, 0);

        final Future<void> queuedAccess = walletFile.access<void>((_) async {
          secondEntered = true;
        });
        final Future<void> queuedRejection = expectLater(
          queuedAccess,
          throwsA(isA<WalletException>()),
        );

        final Future<void> closeFuture = walletFile.close().then((_) {
          closeCompleted = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(walletFile.isClosed, isTrue);
        expect(walletFile.isOpen, isTrue);
        expect(secondEntered, isFalse);
        expect(closeCompleted, isFalse);
        expect(connectCalls, 1);
        expect(createdWallets.single.disconnectCalls, 0);

        releaseFirst.complete();
        expect(await firstAccess, 'signed');
        await queuedRejection;
        await closeFuture;

        expect(secondEntered, isFalse);
        expect(closeCompleted, isTrue);
        expect(connectCalls, 1);
        expect(createdWallets.single.disconnectCalls, 1);
        expect(walletFile.isOpen, isFalse);
      },
    );

    test(
      'LedgerWalletFile.close during pending connect disconnects newly '
      'connected device and skips accessSection',
      () async {
        final Completer<_FakeLedgerWallet> connectCompleter =
            Completer<_FakeLedgerWallet>();
        final _FakeLedgerWallet fakeWallet = _FakeLedgerWallet();
        bool callbackRan = false;

        final LedgerWalletFile walletFile = LedgerWalletFile.forTesting(
          '/tmp/fake-ledger',
          'ledger-device-2',
          (_) => connectCompleter.future,
        );

        final Future<void> pendingAccess = walletFile.access<void>((_) async {
          callbackRan = true;
        });
        final Future<void> expectedRejection = expectLater(
          pendingAccess,
          throwsA(
            isA<WalletException>().having(
              (WalletException e) => e.message,
              'message',
              contains('closed'),
            ),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        final Future<void> closeFuture = walletFile.close();
        connectCompleter.complete(fakeWallet);

        await expectedRejection;
        await closeFuture;

        expect(callbackRan, isFalse);
        expect(fakeWallet.disconnectCalls, 1);
        expect(walletFile.isOpen, isFalse);
      },
    );

    test(
      'walletSign uses captured walletFile.access and survives concurrent '
      'wallet lock clearing kWalletFile',
      () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('wallet_sign_lock_test_');
        final WalletFile? previousWalletFile = kWalletFile;
        final String? previousSelectedAddress = kSelectedAddress;
        final List<String?> previousAddressList = List<String?>.from(
          kDefaultAddressList,
        );
        addTearDown(() {
          kWalletFile = previousWalletFile;
          kSelectedAddress = previousSelectedAddress;
          kDefaultAddressList = previousAddressList;
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        final ({
          KeyStore keyStore,
          String baseAddress,
          KeyStoreWalletFile walletFile,
        }) created = await _createKeyStoreWalletFile(
          walletPath: path.join(tempDir.path, 'keystore'),
          password: 'password-123',
        );

        kWalletFile = created.walletFile;
        kSelectedAddress = created.baseAddress;
        kDefaultAddressList = <String?>[created.baseAddress];

        final Signature signature = await walletSign(
          utf8.encode('hello zenon'),
        );
        expect(signature.signature, isNotEmpty);
        expect(signature.publicKey, isNotEmpty);
        expect(created.walletFile.isOpen, isFalse);

        // When wallet is locked (kWalletFile == null), walletSign throws
        // WalletException instead of a null-check error.
        kWalletFile = null;
        await created.walletFile.close();
        await expectLater(
          () => walletSign(utf8.encode('after lock')),
          throwsA(isA<WalletException>()),
        );
      },
    );
  });
}
