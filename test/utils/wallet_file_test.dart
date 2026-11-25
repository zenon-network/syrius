import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

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
}
