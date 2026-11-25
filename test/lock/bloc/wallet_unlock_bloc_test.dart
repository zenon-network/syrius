import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockWalletFile extends Mock implements WalletFile {}

void main() {
  group('WalletUnlockBloc', () {
    late _MockWalletFile walletFile;
    late bool walletInitCompleted;
    late int failedAttempts;
    late int autoEraseLimit;
    late String? walletPath;
    late WalletFile? storedWalletFile;
    late List<int>? receivedCipherKey;
    late int fetchBalanceCalls;
    late int afterInitCalls;
    late String? unlockedPassword;
    late List<(Object, String)> sentNotifications;

    WalletUnlockSubmitted buildEvent([String password = 'Password1!']) {
      return WalletUnlockSubmitted(
        password: password,
        incorrectPasswordTitle: 'Incorrect password',
        unlockFailedTitle: 'Unlock failed',
        ledgerErrorTitleBuilder: (String details) => 'Ledger: $details',
      );
    }

    WalletUnlockBloc buildBloc({
      Future<WalletFile> Function(String path, String password)? decryptWallet,
      Future<void> Function(List<int> cipherKey)? initWallet,
      Future<void> Function(int numAttempts)? saveNumFailedAttempts,
      Future<void> Function(Object error, String title)? sendErrorNotification,
      void Function()? afterInitCallback,
    }) {
      return WalletUnlockBloc(
        afterUnlockCallback: (String password) async {
          unlockedPassword = password;
        },
        afterInitCallback: afterInitCallback ?? () => afterInitCalls += 1,
        decryptWallet: decryptWallet ?? (_, _) async => walletFile,
        initWalletAfterDecryption:
            initWallet ??
            (List<int> cipherKey) async {
              receivedCipherKey = cipherKey;
              walletInitCompleted = true;
            },
        getWalletPath: () => walletPath,
        setWalletFile: (WalletFile file) => storedWalletFile = file,
        isWalletInitCompleted: () => walletInitCompleted,
        getNumFailedAttempts: () => failedAttempts,
        saveNumFailedAttempts:
            saveNumFailedAttempts ??
            (int value) async {
              failedAttempts = value;
            },
        getAutoEraseWalletLimit: () => autoEraseLimit,
        onFetchBalances: () => fetchBalanceCalls += 1,
        sendErrorNotification:
            sendErrorNotification ??
            (Object error, String title) async {
              sentNotifications.add((error, title));
            },
      );
    }

    setUp(() {
      walletFile = _MockWalletFile();
      walletInitCompleted = false;
      failedAttempts = 0;
      autoEraseLimit = 3;
      walletPath = '/tmp/wallet';
      storedWalletFile = null;
      receivedCipherKey = null;
      fetchBalanceCalls = 0;
      afterInitCalls = 0;
      unlockedPassword = null;
      sentNotifications = <(Object, String)>[];
    });

    test(
      'computes initial remaining attempts from limit and failed attempts',
      () {
        failedAttempts = 1;
        autoEraseLimit = 3;
        final WalletUnlockBloc bloc = buildBloc();
        addTearDown(bloc.close);

        expect(bloc.state, const WalletUnlockState(remainingAttempts: 2));
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'ignores empty password submission',
      build: buildBloc,
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('')),
      expect: () => const <WalletUnlockState>[],
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'runs first-time initialization flow on initial unlock',
      setUp: () {
        failedAttempts = 2;
      },
      build: buildBloc,
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('MyPass123!')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 1,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.initializing,
          remainingAttempts: 1,
          nonce: 2,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.success,
          remainingAttempts: 3,
          nonce: 3,
        ),
      ],
      verify: (_) {
        expect(storedWalletFile, walletFile);
        expect(receivedCipherKey, Crypto.digest(utf8.encode('MyPass123!')));
        expect(fetchBalanceCalls, 1);
        expect(afterInitCalls, 1);
        expect(unlockedPassword, isNull);
        expect(failedAttempts, 0);
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'runs subsequent unlock callback when wallet is already initialized',
      setUp: () {
        walletInitCompleted = true;
        failedAttempts = 1;
      },
      build: buildBloc,
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('MyPass123!')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 2,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.success,
          remainingAttempts: 3,
          nonce: 2,
        ),
      ],
      verify: (_) {
        expect(unlockedPassword, 'MyPass123!');
        expect(receivedCipherKey, isNull);
        expect(afterInitCalls, 0);
        expect(failedAttempts, 0);
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'increments failed attempts on IncorrectPasswordException',
      build: () => buildBloc(
        decryptWallet: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('bad')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 3,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: 2,
          nonce: 2,
        ),
      ],
      verify: (_) {
        expect(failedAttempts, 1);
        expect(sentNotifications, hasLength(1));
        expect(sentNotifications.single.$2, 'Incorrect password');
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'triggers auto-erase when failed attempts reach limit',
      setUp: () {
        failedAttempts = 2;
        autoEraseLimit = 3;
      },
      build: () => buildBloc(
        decryptWallet: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('bad')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 1,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.autoEraseTriggered,
          remainingAttempts: 0,
          nonce: 2,
        ),
      ],
      verify: (_) {
        expect(failedAttempts, 3);
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'reports LedgerError without incrementing failed attempts',
      build: () => buildBloc(
        decryptWallet: (_, _) => Future<WalletFile>.error(
          const LedgerError.connectionError(origMessage: 'Device disconnected'),
        ),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('MyPass123!')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 3,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: 3,
          nonce: 2,
        ),
      ],
      verify: (_) {
        expect(failedAttempts, 0);
        expect(sentNotifications, hasLength(1));
        expect(sentNotifications.single.$2, startsWith('Ledger: '));
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'reports generic unlock failure when wallet path is null',
      setUp: () {
        walletPath = null;
      },
      build: buildBloc,
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('MyPass123!')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 3,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: 3,
          nonce: 2,
        ),
      ],
      verify: (_) {
        expect(failedAttempts, 0);
        expect(sentNotifications, hasLength(1));
        expect(sentNotifications.single.$2, 'Unlock failed');
      },
    );

    test('drops concurrent unlock submissions while busy', () async {
      int decryptCalls = 0;
      final Completer<WalletFile> completer = Completer<WalletFile>();
      walletInitCompleted = true;

      final WalletUnlockBloc bloc = buildBloc(
        decryptWallet: (_, _) {
          decryptCalls += 1;
          return completer.future;
        },
      );
      addTearDown(bloc.close);

      bloc
        ..add(buildEvent('first'))
        ..add(buildEvent('second'));

      await Future<void>.delayed(Duration.zero);
      completer.complete(walletFile);
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<WalletUnlockState>().having(
            (WalletUnlockState s) => s.status,
            'status',
            WalletUnlockStatus.success,
          ),
        ),
      );

      expect(decryptCalls, 1);
    });

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'runs afterInitCallback before failed-attempt reset even if reset throws',
      build: () => buildBloc(
        afterInitCallback: () => afterInitCalls += 1,
        saveNumFailedAttempts: (_) =>
            Future<void>.error(StateError('prefs write failed')),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('MyPass123!')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 3,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.initializing,
          remainingAttempts: 3,
          nonce: 2,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: 3,
          nonce: 3,
        ),
      ],
      errors: () => <Matcher>[isA<StateError>()],
      verify: (_) {
        expect(afterInitCalls, 1);
      },
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'emits failure and reports error when attempt persistence fails below '
      'limit',
      build: () => buildBloc(
        decryptWallet: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
        saveNumFailedAttempts: (_) =>
            Future<void>.error(StateError('disk full')),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('bad')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 3,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: 2,
          nonce: 2,
        ),
      ],
      errors: () => <Matcher>[
        isA<IncorrectPasswordException>(),
        isA<StateError>(),
      ],
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'still emits autoEraseTriggered when attempt persistence fails at limit',
      setUp: () {
        failedAttempts = 2;
        autoEraseLimit = 3;
      },
      build: () => buildBloc(
        decryptWallet: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
        saveNumFailedAttempts: (_) =>
            Future<void>.error(StateError('disk full')),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('bad')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 1,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.autoEraseTriggered,
          remainingAttempts: 0,
          nonce: 2,
        ),
      ],
      errors: () => <Matcher>[
        isA<IncorrectPasswordException>(),
        isA<StateError>(),
      ],
    );

    blocTest<WalletUnlockBloc, WalletUnlockState>(
      'still emits failure when error notification itself throws',
      build: () => buildBloc(
        decryptWallet: (_, _) =>
            Future<WalletFile>.error(IncorrectPasswordException()),
        sendErrorNotification: (_, _) =>
            Future<void>.error(StateError('notify failed')),
      ),
      act: (WalletUnlockBloc bloc) => bloc.add(buildEvent('bad')),
      expect: () => const <WalletUnlockState>[
        WalletUnlockState(
          status: WalletUnlockStatus.decrypting,
          remainingAttempts: 3,
          nonce: 1,
        ),
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: 2,
          nonce: 2,
        ),
      ],
      errors: () => <Matcher>[
        isA<IncorrectPasswordException>(),
        isA<StateError>(),
      ],
      verify: (_) {
        expect(failedAttempts, 1);
      },
    );
  });
}
