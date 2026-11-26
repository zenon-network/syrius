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
      'emits [loading, failure(reason: fileTooLarge)] on '
      'WalletFileReadException',
      build: () => DecryptWalletFileBloc(
        decryptWalletFile: (_, _) => Future<WalletFile>.error(
          WalletFileReadException(
            WalletFileReadFailureReason.fileTooLarge,
            'Wallet file is too large',
          ),
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
              (DecryptWalletFileFailure s) => s.reason,
              'reason',
              DecryptWalletFileFailureReason.fileTooLarge,
            )
            .having(
              (DecryptWalletFileFailure s) => s.error,
              'error',
              isA<WalletFileReadException>(),
            ),
      ],
    );

    blocTest<DecryptWalletFileBloc, DecryptWalletFileState>(
      'classifies notFound, notRegularFile, unsupportedWalletType, and '
      'FormatException',
      build: () {
        int call = 0;
        return DecryptWalletFileBloc(
          decryptWalletFile: (_, _) {
            call += 1;
            return switch (call) {
              1 => Future<WalletFile>.error(
                WalletFileReadException(
                  WalletFileReadFailureReason.notFound,
                  'missing',
                ),
              ),
              2 => Future<WalletFile>.error(
                WalletFileReadException(
                  WalletFileReadFailureReason.notRegularFile,
                  'dir',
                ),
              ),
              3 => Future<WalletFile>.error(
                WalletFileReadException(
                  WalletFileReadFailureReason.unsupportedWalletType,
                  'unsupported',
                ),
              ),
              _ => Future<WalletFile>.error(
                const FormatException('Invalid keystore file format'),
              ),
            };
          },
        );
      },
      act: (DecryptWalletFileBloc bloc) async {
        bloc.add(const DecryptWalletFileRequested(path: '/1', password: 'p'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DecryptWalletFileRequested(path: '/2', password: 'p'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DecryptWalletFileRequested(path: '/3', password: 'p'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DecryptWalletFileRequested(path: '/4', password: 'p'));
      },
      expect: () => <Matcher>[
        isA<DecryptWalletFileLoading>(),
        isA<DecryptWalletFileFailure>().having(
          (DecryptWalletFileFailure s) => s.reason,
          'reason',
          DecryptWalletFileFailureReason.fileNotFound,
        ),
        isA<DecryptWalletFileLoading>(),
        isA<DecryptWalletFileFailure>().having(
          (DecryptWalletFileFailure s) => s.reason,
          'reason',
          DecryptWalletFileFailureReason.notRegularFile,
        ),
        isA<DecryptWalletFileLoading>(),
        isA<DecryptWalletFileFailure>().having(
          (DecryptWalletFileFailure s) => s.reason,
          'reason',
          DecryptWalletFileFailureReason.unsupportedWalletType,
        ),
        isA<DecryptWalletFileLoading>(),
        isA<DecryptWalletFileFailure>().having(
          (DecryptWalletFileFailure s) => s.reason,
          'reason',
          DecryptWalletFileFailureReason.invalidKeystoreFormat,
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
