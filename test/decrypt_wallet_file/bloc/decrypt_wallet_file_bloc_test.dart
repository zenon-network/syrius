import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockKeyStoreWalletFile extends Mock implements KeyStoreWalletFile {}

void main() {
  group('DecryptWalletFileBloc', () {
    late _MockKeyStoreWalletFile walletFile;

    setUp(() {
      walletFile = _MockKeyStoreWalletFile();
    });

    test('initial state is DecryptWalletFileInitial', () {
      final DecryptWalletFileBloc bloc = DecryptWalletFileBloc(
        decryptWalletFile: (_, _) async => walletFile,
      );
      addTearDown(bloc.close);

      expect(bloc.state, const DecryptWalletFileInitial());
    });

    blocTest<DecryptWalletFileBloc, DecryptWalletFileState>(
      'emits [loading, success] when decryption succeeds',
      build: () => DecryptWalletFileBloc(
        decryptWalletFile: (String path, String password) async {
          expect(path, '/tmp/wallet');
          expect(password, 'Secret123!');
          return walletFile;
        },
      ),
      act: (DecryptWalletFileBloc bloc) => bloc.add(
        const DecryptWalletFileRequested(
          path: '/tmp/wallet',
          password: 'Secret123!',
        ),
      ),
      expect: () => <DecryptWalletFileState>[
        const DecryptWalletFileLoading(),
        DecryptWalletFileSuccess(walletFile: walletFile),
      ],
    );

    blocTest<DecryptWalletFileBloc, DecryptWalletFileState>(
      'emits [loading, failure(isIncorrectPassword: true)] on wrong password',
      build: () => DecryptWalletFileBloc(
        decryptWalletFile: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
      ),
      act: (DecryptWalletFileBloc bloc) => bloc.add(
        const DecryptWalletFileRequested(
          path: '/tmp/wallet',
          password: 'wrong',
        ),
      ),
      expect: () => <Matcher>[
        isA<DecryptWalletFileLoading>(),
        isA<DecryptWalletFileFailure>()
            .having(
              (DecryptWalletFileFailure s) => s.isIncorrectPassword,
              'isIncorrectPassword',
              isTrue,
            )
            .having(
              (DecryptWalletFileFailure s) => s.error,
              'error',
              isA<IncorrectPasswordException>(),
            ),
      ],
    );

    blocTest<DecryptWalletFileBloc, DecryptWalletFileState>(
      'emits [loading, failure(isIncorrectPassword: false)] on WalletException',
      build: () => DecryptWalletFileBloc(
        decryptWalletFile: (_, _) => Future<WalletFile>.error(
          WalletException('Wallet file is too large'),
        ),
      ),
      act: (DecryptWalletFileBloc bloc) => bloc.add(
        const DecryptWalletFileRequested(
          path: '/tmp/huge.bak',
          password: 'Secret123!',
        ),
      ),
      expect: () => <Matcher>[
        isA<DecryptWalletFileLoading>(),
        isA<DecryptWalletFileFailure>()
            .having(
              (DecryptWalletFileFailure s) => s.isIncorrectPassword,
              'isIncorrectPassword',
              isFalse,
            )
            .having(
              (DecryptWalletFileFailure s) => s.error,
              'error',
              isA<WalletException>(),
            ),
      ],
    );

    test('drops concurrent decrypt requests while in flight', () async {
      int calls = 0;
      final Completer<WalletFile> completer = Completer<WalletFile>();
      final DecryptWalletFileBloc bloc = DecryptWalletFileBloc(
        decryptWalletFile: (_, _) {
          calls += 1;
          return completer.future;
        },
      );
      addTearDown(bloc.close);

      bloc
        ..add(const DecryptWalletFileRequested(path: '/a', password: 'p1'))
        ..add(const DecryptWalletFileRequested(path: '/b', password: 'p2'));

      await Future<void>.delayed(Duration.zero);
      completer.complete(walletFile);
      await expectLater(
        bloc.stream,
        emitsThrough(DecryptWalletFileSuccess(walletFile: walletFile)),
      );

      expect(calls, 1);
    });
  });
}
