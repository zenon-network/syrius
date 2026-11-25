import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/dump_mnemonic/dump_mnemonic.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _FakeKeyStore extends Fake implements KeyStore {
  _FakeKeyStore(this.mnemonic);

  @override
  final String? mnemonic;
}

class _FakeWalletFile extends Fake implements WalletFile {
  _FakeWalletFile(this.mnemonic);

  final String mnemonic;
  bool closed = false;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) async {
    try {
      return await accessSection(_FakeKeyStore(mnemonic));
    } finally {
      closed = true;
    }
  }
}

void main() {
  group('DumpMnemonicBloc', () {
    late _FakeWalletFile fakeWalletFile;

    setUp(() {
      fakeWalletFile = _FakeWalletFile('alpha beta gamma');
    });

    blocTest<DumpMnemonicBloc, DumpMnemonicState>(
      'unlocks mnemonic words and closes wallet file via access()',
      build: () => DumpMnemonicBloc(
        walletPathProvider: () => '/tmp/wallet',
        decryptWalletFile: (_, _) async => fakeWalletFile,
      ),
      act: (DumpMnemonicBloc bloc) =>
          bloc.add(const DumpMnemonicSubmitted(password: 'secret')),
      expect: () => const <DumpMnemonicState>[
        DumpMnemonicLoading(),
        DumpMnemonicUnlocked(seedWords: <String>['alpha', 'beta', 'gamma']),
      ],
      verify: (_) {
        expect(fakeWalletFile.closed, isTrue);
      },
    );

    blocTest<DumpMnemonicBloc, DumpMnemonicState>(
      'emits IncorrectPassword on wrong password and clears on edit',
      build: () => DumpMnemonicBloc(
        walletPathProvider: () => '/tmp/wallet',
        decryptWalletFile: (_, _) async => throw IncorrectPasswordException(),
      ),
      act: (DumpMnemonicBloc bloc) {
        bloc
          ..add(const DumpMnemonicSubmitted(password: 'bad'))
          ..add(const DumpMnemonicErrorCleared());
      },
      expect: () => const <DumpMnemonicState>[
        DumpMnemonicLoading(),
        DumpMnemonicIncorrectPassword(),
        DumpMnemonicInitial(),
      ],
    );

    blocTest<DumpMnemonicBloc, DumpMnemonicState>(
      'emits DumpMnemonicFailure on unexpected error',
      build: () => DumpMnemonicBloc(
        walletPathProvider: () => '/tmp/wallet',
        decryptWalletFile: (_, _) async => throw StateError('corrupt'),
      ),
      act: (DumpMnemonicBloc bloc) =>
          bloc.add(const DumpMnemonicSubmitted(password: 'secret')),
      expect: () => <Matcher>[
        isA<DumpMnemonicLoading>(),
        isA<DumpMnemonicFailure>().having(
          (DumpMnemonicFailure s) => s.errorMessage,
          'errorMessage',
          contains('corrupt'),
        ),
      ],
    );
  });
}
