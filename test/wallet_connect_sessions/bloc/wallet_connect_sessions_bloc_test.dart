import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/wallet_connect_sessions/wallet_connect_sessions.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

SessionData _buildSession(String topic, {bool acknowledged = true}) {
  return SessionData(
    topic: topic,
    pairingTopic: 'pairing-$topic',
    relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
    expiry: 1700000000,
    acknowledged: acknowledged,
    controller: 'controller-key',
    namespaces: const <String, Namespace>{
      'zenon': Namespace(
        chains: <String>['zenon:1'],
        accounts: <String>['zenon:1:z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7'],
        methods: <String>['znn_info', 'znn_sign', 'znn_send'],
        events: <String>['chainIdChange', 'addressChange'],
      ),
    },
    self: const ConnectionMetadata(
      publicKey: 'self-key',
      metadata: PairingMetadata(
        name: 's y r i u s',
        description: 'Zenon wallet',
        url: 'https://zenon.network',
      ),
    ),
    peer: ConnectionMetadata(
      publicKey: 'peer-key-$topic',
      metadata: PairingMetadata(
        name: 'dApp $topic',
        description: 'Test dApp',
        url: 'https://example.invalid/$topic',
      ),
    ),
  );
}

void main() {
  group('WalletConnectSessionsBloc', () {
    late _MockWeb3WalletService web3WalletService;
    late ValueNotifier<List<SessionData>> sessionsNotifier;
    late SessionData firstSession;
    late SessionData secondSession;

    WalletConnectSessionsBloc buildBloc() =>
        WalletConnectSessionsBloc(web3WalletService: web3WalletService);

    setUp(() {
      web3WalletService = _MockWeb3WalletService();
      firstSession = _buildSession('session-1');
      secondSession = _buildSession('session-2', acknowledged: false);
      sessionsNotifier = ValueNotifier<List<SessionData>>(<SessionData>[
        firstSession,
      ]);

      when(() => web3WalletService.sessions).thenReturn(sessionsNotifier);
      when(
        () => web3WalletService.disconnectSession(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      sessionsNotifier.dispose();
    });

    test('initial state reflects current service sessions', () {
      final WalletConnectSessionsBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(
        bloc.state,
        WalletConnectSessionsState(sessions: <SessionData>[firstSession]),
      );
    });

    blocTest<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      'emits updated sessions reactively when service notifier changes',
      build: buildBloc,
      act: (WalletConnectSessionsBloc _) {
        sessionsNotifier.value = <SessionData>[firstSession, secondSession];
      },
      expect: () => <WalletConnectSessionsState>[
        WalletConnectSessionsState(
          sessions: <SessionData>[firstSession, secondSession],
        ),
      ],
    );

    blocTest<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      'disconnects session and clears in-flight topic on success',
      setUp: () {
        when(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).thenAnswer((_) async {
          sessionsNotifier.value = const <SessionData>[];
        });
      },
      build: buildBloc,
      act: (WalletConnectSessionsBloc bloc) {
        bloc.add(
          const WalletConnectSessionDisconnectRequested(topic: 'session-1'),
        );
      },
      verify: (_) {
        verify(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).called(1);
      },
      expect: () => <WalletConnectSessionsState>[
        WalletConnectSessionsState(
          sessions: <SessionData>[firstSession],
          disconnectingTopics: const <String>{'session-1'},
        ),
        const WalletConnectSessionsState(),
      ],
    );

    blocTest<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      'ignores duplicate disconnect request while topic is in flight',
      setUp: () {
        final Completer<void> completer = Completer<void>();
        when(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).thenAnswer((_) => completer.future);
      },
      build: buildBloc,
      act: (WalletConnectSessionsBloc bloc) {
        bloc
          ..add(
            const WalletConnectSessionDisconnectRequested(topic: 'session-1'),
          )
          ..add(
            const WalletConnectSessionDisconnectRequested(topic: 'session-1'),
          );
      },
      verify: (_) {
        verify(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).called(1);
      },
      expect: () => <WalletConnectSessionsState>[
        WalletConnectSessionsState(
          sessions: <SessionData>[firstSession],
          disconnectingTopics: const <String>{'session-1'},
        ),
      ],
    );

    blocTest<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      'emits error state and clears in-flight topic when disconnect fails',
      setUp: () {
        when(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).thenThrow(StateError('disconnect failed'));
      },
      build: buildBloc,
      act: (WalletConnectSessionsBloc bloc) {
        bloc.add(
          const WalletConnectSessionDisconnectRequested(topic: 'session-1'),
        );
      },
      errors: () => <Matcher>[isA<StateError>()],
      expect: () => <Object>[
        WalletConnectSessionsState(
          sessions: <SessionData>[firstSession],
          disconnectingTopics: const <String>{'session-1'},
        ),
        isA<WalletConnectSessionsState>()
            .having(
              (WalletConnectSessionsState s) => s.sessions,
              'sessions',
              <SessionData>[firstSession],
            )
            .having(
              (WalletConnectSessionsState s) => s.disconnectingTopics,
              'disconnectingTopics',
              isEmpty,
            )
            .having(
              (WalletConnectSessionsState s) => s.error,
              'error',
              isA<StateError>(),
            ),
      ],
    );

    blocTest<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      'clears error on refresh request',
      setUp: () {
        when(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).thenThrow(StateError('boom'));
      },
      build: buildBloc,
      act: (WalletConnectSessionsBloc bloc) async {
        bloc.add(
          const WalletConnectSessionDisconnectRequested(topic: 'session-1'),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const WalletConnectSessionsRefreshRequested());
      },
      errors: () => <Matcher>[isA<StateError>()],
      expect: () => <Object>[
        WalletConnectSessionsState(
          sessions: <SessionData>[firstSession],
          disconnectingTopics: const <String>{'session-1'},
        ),
        isA<WalletConnectSessionsState>().having(
          (WalletConnectSessionsState s) => s.error,
          'error',
          isA<StateError>(),
        ),
        WalletConnectSessionsState(
          sessions: <SessionData>[firstSession],
          errorCount: 1,
        ),
      ],
    );

    late Completer<void> firstDisconnect;
    late Completer<void> secondDisconnect;
    blocTest<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      'increments errorCount for concurrent equal errors across topics',
      setUp: () {
        sessionsNotifier.value = <SessionData>[firstSession, secondSession];
        firstDisconnect = Completer<void>();
        secondDisconnect = Completer<void>();
        when(
          () => web3WalletService.disconnectSession(topic: 'session-1'),
        ).thenAnswer((_) => firstDisconnect.future);
        when(
          () => web3WalletService.disconnectSession(topic: 'session-2'),
        ).thenAnswer((_) => secondDisconnect.future);
      },
      build: buildBloc,
      act: (WalletConnectSessionsBloc bloc) async {
        bloc
          ..add(
            const WalletConnectSessionDisconnectRequested(topic: 'session-1'),
          )
          ..add(
            const WalletConnectSessionDisconnectRequested(topic: 'session-2'),
          );
        await Future<void>.delayed(Duration.zero);
        firstDisconnect.completeError('same-error');
        secondDisconnect.completeError('same-error');
        await Future<void>.delayed(Duration.zero);
      },
      errors: () => <Object>['same-error', 'same-error'],
      verify: (WalletConnectSessionsBloc bloc) {
        expect(bloc.state.errorCount, 2);
        expect(bloc.state.error, 'same-error');
        expect(bloc.state.disconnectingTopics, isEmpty);
      },
    );

    test('detaches listener on close', () async {
      final WalletConnectSessionsBloc bloc = buildBloc();
      // Accessing ChangeNotifier.hasListeners to verify listener cleanup.
      // ignore: invalid_use_of_protected_member
      expect(sessionsNotifier.hasListeners, isTrue);

      await bloc.close();

      // Verify the ChangeNotifier listener was detached on close.
      // ignore: invalid_use_of_protected_member
      expect(sessionsNotifier.hasListeners, isFalse);
    });
  });
}
