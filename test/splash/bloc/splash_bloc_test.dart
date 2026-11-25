import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

void main() {
  group('SplashBloc', () {
    late List<String> callLog;
    late String? walletPath;
    late String? selectedNode;

    SplashBloc buildBloc() {
      return SplashBloc(
        setWalletInitIncomplete: () => callLog.add('setWalletInitIncomplete'),
        clearLastNotification: () async => callLog.add('clearLastNotification'),
        stopWebSocketClient: () => callLog.add('stopWebSocketClient'),
        clearAutoReceivePool: () => callLog.add('clearAutoReceivePool'),
        stopHtlcSwapSync: () async => callLog.add('stopHtlcSwapSync'),
        closeHtlcSwapStorage: () async => callLog.add('closeHtlcSwapStorage'),
        closeHive: () async => callLog.add('closeHive'),
        deleteCacheBox: (String boxName) async =>
            callLog.add('deleteCacheBox:$boxName'),
        deleteWeb3Cache: () async => callLog.add('deleteWeb3Cache'),
        deleteHtlcDatabase: () async => callLog.add('deleteHtlcDatabase'),
        deleteLegacyHtlcBoxes: () async => callLog.add('deleteLegacyHtlcBoxes'),
        deleteKeyStoreBox: () async => callLog.add('deleteKeyStoreBox'),
        closeAndDeleteWalletFile: () async {
          callLog.add('closeAndDeleteWalletFile');
          walletPath = null;
        },
        getWalletPath: () => walletPath,
        getSelectedNode: () => selectedNode,
        exitApp: () => callLog.add('exitApp'),
      );
    }

    setUp(() {
      callLog = <String>[];
      walletPath = null;
      selectedNode = null;
    });

    test('initial state is SplashInitial', () {
      final SplashBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const SplashInitial());
    });

    blocTest<SplashBloc, SplashState>(
      'normal flow navigates to accessWallet when no wallet path exists',
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.normal,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => const <SplashState>[
        SplashInProgress(),
        SplashNavigateTo(SplashDestination.accessWallet),
      ],
      verify: (_) => expect(callLog, <String>['initApp']),
    );

    blocTest<SplashBloc, SplashState>(
      'normal flow navigates to home when wallet path and selected node exist',
      setUp: () {
        walletPath = '/tmp/wallet';
        selectedNode = kEmbeddedNode;
      },
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.normal,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => const <SplashState>[
        SplashInProgress(),
        SplashNavigateTo(SplashDestination.home),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'normal flow navigates to nodeManagement when wallet exists without node',
      setUp: () {
        walletPath = '/tmp/wallet';
        selectedNode = null;
      },
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.normal,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => const <SplashState>[
        SplashInProgress(),
        SplashNavigateTo(SplashDestination.nodeManagement),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'development flow navigates directly to home when wallet path exists',
      setUp: () {
        walletPath = '/tmp/wallet';
        selectedNode = null;
      },
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.development,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => const <SplashState>[
        SplashInProgress(),
        SplashNavigateTo(SplashDestination.home),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'deleteCache flow preserves HTLC database and keystore, deletes caches, '
      'and exits',
      setUp: () {
        walletPath = '/tmp/wallet';
      },
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.deleteCache,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => const <SplashState>[
        SplashInProgress(),
        SplashCacheDeleted(),
      ],
      verify: (_) {
        expect(callLog, <String>[
          'deleteWeb3Cache',
          'stopHtlcSwapSync',
          'closeHtlcSwapStorage',
          'closeHive',
          for (final String box in kCacheBoxesToBeDeleted)
            'deleteCacheBox:$box',
          'exitApp',
        ]);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'resetWallet flow executes full reset sequence in exact order and '
      'navigates to accessWallet',
      setUp: () {
        walletPath = '/tmp/wallet';
        selectedNode = kEmbeddedNode;
      },
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.resetWallet,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => const <SplashState>[
        SplashInProgress(),
        SplashNavigateTo(SplashDestination.accessWallet),
      ],
      verify: (_) {
        expect(callLog, <String>[
          'setWalletInitIncomplete',
          'clearLastNotification',
          'stopWebSocketClient',
          'clearAutoReceivePool',
          'deleteWeb3Cache',
          'stopHtlcSwapSync',
          'closeHtlcSwapStorage',
          'closeHive',
          for (final String box in kCacheBoxesToBeDeleted)
            'deleteCacheBox:$box',
          'deleteHtlcDatabase',
          'deleteLegacyHtlcBoxes',
          'deleteKeyStoreBox',
          'closeAndDeleteWalletFile',
          'initApp',
        ]);
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits SplashFailure(failedWhileClearing: true) when deleteWeb3Cache '
      'throws during resetWallet without deleting wallet files',
      build: () => SplashBloc(
        setWalletInitIncomplete: () => callLog.add('setWalletInitIncomplete'),
        clearLastNotification: () async => callLog.add('clearLastNotification'),
        stopWebSocketClient: () => callLog.add('stopWebSocketClient'),
        clearAutoReceivePool: () => callLog.add('clearAutoReceivePool'),
        deleteWeb3Cache: () => Future<void>.error(StateError('wc reset hung')),
        deleteKeyStoreBox: () async => callLog.add('deleteKeyStoreBox'),
        closeAndDeleteWalletFile: () async =>
            callLog.add('closeAndDeleteWalletFile'),
      ),
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.resetWallet,
          initApp: () async => callLog.add('initApp'),
        ),
      ),
      expect: () => <Matcher>[
        isA<SplashInProgress>(),
        isA<SplashFailure>()
            .having(
              (SplashFailure s) => s.failedWhileClearing,
              'failedWhileClearing',
              isTrue,
            )
            .having(
              (SplashFailure s) => s.error.toString(),
              'error',
              contains('wc reset hung'),
            ),
      ],
      verify: (_) {
        expect(callLog, isNot(contains('deleteKeyStoreBox')));
        expect(callLog, isNot(contains('closeAndDeleteWalletFile')));
      },
    );

    blocTest<SplashBloc, SplashState>(
      'emits SplashFailure(failedWhileClearing: false) when initApp throws '
      'after clearing finishes in resetWallet',
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.resetWallet,
          initApp: () => Future<void>.error(Exception('post-reset init boom')),
        ),
      ),
      expect: () => <Matcher>[
        isA<SplashInProgress>(),
        isA<SplashFailure>().having(
          (SplashFailure s) => s.failedWhileClearing,
          'failedWhileClearing',
          isFalse,
        ),
      ],
    );

    blocTest<SplashBloc, SplashState>(
      'emits SplashFailure when initialization throws',
      build: buildBloc,
      act: (SplashBloc bloc) => bloc.add(
        SplashStarted(
          flow: SplashFlow.normal,
          initApp: () => Future<void>.error(Exception('init boom')),
        ),
      ),
      expect: () => <Matcher>[
        isA<SplashInProgress>(),
        isA<SplashFailure>().having(
          (SplashFailure s) => s.error.toString(),
          'error',
          contains('init boom'),
        ),
      ],
    );

    test('drops duplicate SplashStarted events while running', () async {
      int initCalls = 0;
      final Completer<void> completer = Completer<void>();
      final SplashBloc bloc = buildBloc();
      addTearDown(bloc.close);

      bloc
        ..add(
          SplashStarted(
            flow: SplashFlow.normal,
            initApp: () {
              initCalls += 1;
              return completer.future;
            },
          ),
        )
        ..add(
          SplashStarted(
            flow: SplashFlow.normal,
            initApp: () async {
              initCalls += 1;
            },
          ),
        );

      await Future<void>.delayed(Duration.zero);
      completer.complete();
      await expectLater(
        bloc.stream,
        emitsThrough(const SplashNavigateTo(SplashDestination.accessWallet)),
      );

      expect(initCalls, 1);
    });
  });
}
