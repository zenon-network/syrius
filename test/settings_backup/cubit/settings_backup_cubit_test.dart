import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_backup/settings_backup.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _FakeWalletFile extends Fake implements WalletFile {
  _FakeWalletFile({
    required this.isHardwareWallet,
    this.mnemonic = 'abandon abandon abandon',
    this.throwOnAccess = false,
  });

  @override
  final bool isHardwareWallet;

  final String mnemonic;
  final bool throwOnAccess;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) async {
    if (throwOnAccess) {
      throw StateError('wallet locked');
    }
    final KeyStore keyStore = _FakeKeyStore(mnemonic);
    return await accessSection(keyStore);
  }
}

class _FakeKeyStore extends Fake implements KeyStore {
  _FakeKeyStore(this.mnemonic);

  @override
  final String? mnemonic;
}

void main() {
  group('SettingsBackupCubit', () {
    test('disables backup for hardware wallets', () {
      final SettingsBackupCubit cubit = SettingsBackupCubit(
        walletFile: _FakeWalletFile(isHardwareWallet: true),
      );
      addTearDown(cubit.close);

      expect(cubit.state, const SettingsBackupIdle(canBackup: false));
    });

    blocTest<SettingsBackupCubit, SettingsBackupState>(
      'loads mnemonic seed and emits [loading, seedLoaded, idle]',
      build: () => SettingsBackupCubit(
        walletFile: _FakeWalletFile(
          isHardwareWallet: false,
          mnemonic: 'seed words here',
        ),
      ),
      act: (SettingsBackupCubit cubit) => cubit.requestBackupSeed(),
      expect: () => const <SettingsBackupState>[
        SettingsBackupLoading(canBackup: true),
        SettingsBackupSeedLoaded(seed: 'seed words here', canBackup: true),
        SettingsBackupIdle(canBackup: true),
      ],
    );

    blocTest<SettingsBackupCubit, SettingsBackupState>(
      'emits failure when accessing wallet throws',
      build: () => SettingsBackupCubit(
        walletFile: _FakeWalletFile(
          isHardwareWallet: false,
          throwOnAccess: true,
        ),
      ),
      act: (SettingsBackupCubit cubit) => cubit.requestBackupSeed(),
      expect: () => <Matcher>[
        isA<SettingsBackupLoading>(),
        isA<SettingsBackupFailure>(),
        isA<SettingsBackupIdle>(),
      ],
    );
  });
}
