import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/wallet_connect_pairings/wallet_connect_pairings.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/wallet_connect_metadata_utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

PairingInfo _buildPairing(String topic, {bool active = true}) {
  return PairingInfo(
    topic: topic,
    expiry: 1700000000,
    relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
    active: active,
    peerMetadata: PairingMetadata(
      name: 'dApp $topic',
      description: 'Test dApp',
      url: 'https://example.invalid/$topic',
    ),
  );
}

void main() {
  group('WalletConnectPairingsBloc', () {
    late _MockWeb3WalletService web3WalletService;
    late ValueNotifier<List<PairingInfo>> pairingsNotifier;
    late PairingInfo firstPairing;
    late PairingInfo secondPairing;

    WalletConnectPairingsBloc buildBloc() => WalletConnectPairingsBloc(
      web3WalletService: web3WalletService,
    );

    setUp(() {
      web3WalletService = _MockWeb3WalletService();
      firstPairing = _buildPairing('topic-1');
      secondPairing = _buildPairing('topic-2', active: false);
      pairingsNotifier = ValueNotifier<List<PairingInfo>>(<PairingInfo>[
        firstPairing,
      ]);

      when(() => web3WalletService.pairings).thenReturn(pairingsNotifier);
      when(
        () => web3WalletService.deactivatePairing(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      pairingsNotifier.dispose();
    });

    test('initial state reflects current service pairings', () {
      final WalletConnectPairingsBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(
        bloc.state,
        WalletConnectPairingsState(pairings: <PairingInfo>[firstPairing]),
      );
    });

    blocTest<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      'emits updated pairings reactively when service notifier changes',
      build: buildBloc,
      act: (WalletConnectPairingsBloc _) {
        pairingsNotifier.value = <PairingInfo>[firstPairing, secondPairing];
      },
      expect: () => <WalletConnectPairingsState>[
        WalletConnectPairingsState(
          pairings: <PairingInfo>[firstPairing, secondPairing],
        ),
      ],
    );

    blocTest<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      'deactivates pairing and clears in-flight topic on success',
      setUp: () {
        when(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).thenAnswer((_) async {
          pairingsNotifier.value = const <PairingInfo>[];
        });
      },
      build: buildBloc,
      act: (WalletConnectPairingsBloc bloc) {
        bloc.add(
          const WalletConnectPairingDeactivateRequested(topic: 'topic-1'),
        );
      },
      verify: (_) {
        verify(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).called(1);
      },
      expect: () => <WalletConnectPairingsState>[
        WalletConnectPairingsState(
          pairings: <PairingInfo>[firstPairing],
          deactivatingTopics: const <String>{'topic-1'},
        ),
        const WalletConnectPairingsState(),
      ],
    );

    blocTest<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      'ignores duplicate deactivation request while topic is in flight',
      setUp: () {
        final Completer<void> completer = Completer<void>();
        when(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).thenAnswer((_) => completer.future);
      },
      build: buildBloc,
      act: (WalletConnectPairingsBloc bloc) {
        bloc
          ..add(
            const WalletConnectPairingDeactivateRequested(topic: 'topic-1'),
          )
          ..add(
            const WalletConnectPairingDeactivateRequested(topic: 'topic-1'),
          );
      },
      verify: (_) {
        verify(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).called(1);
      },
      expect: () => <WalletConnectPairingsState>[
        WalletConnectPairingsState(
          pairings: <PairingInfo>[firstPairing],
          deactivatingTopics: const <String>{'topic-1'},
        ),
      ],
    );

    blocTest<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      'emits error state and clears in-flight topic when deactivation fails',
      setUp: () {
        when(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).thenThrow(StateError('deactivate failed'));
      },
      build: buildBloc,
      act: (WalletConnectPairingsBloc bloc) {
        bloc.add(
          const WalletConnectPairingDeactivateRequested(topic: 'topic-1'),
        );
      },
      errors: () => <Matcher>[isA<StateError>()],
      expect: () => <Object>[
        WalletConnectPairingsState(
          pairings: <PairingInfo>[firstPairing],
          deactivatingTopics: const <String>{'topic-1'},
        ),
        isA<WalletConnectPairingsState>()
            .having(
              (WalletConnectPairingsState s) => s.pairings,
              'pairings',
              <PairingInfo>[firstPairing],
            )
            .having(
              (WalletConnectPairingsState s) => s.deactivatingTopics,
              'deactivatingTopics',
              isEmpty,
            )
            .having(
              (WalletConnectPairingsState s) => s.error,
              'error',
              isA<StateError>(),
            ),
      ],
    );

    blocTest<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      'clears error on refresh request',
      setUp: () {
        when(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).thenThrow(StateError('boom'));
      },
      build: buildBloc,
      act: (WalletConnectPairingsBloc bloc) async {
        bloc.add(
          const WalletConnectPairingDeactivateRequested(topic: 'topic-1'),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const WalletConnectPairingsRefreshRequested());
      },
      errors: () => <Matcher>[isA<StateError>()],
      expect: () => <Object>[
        WalletConnectPairingsState(
          pairings: <PairingInfo>[firstPairing],
          deactivatingTopics: const <String>{'topic-1'},
        ),
        isA<WalletConnectPairingsState>().having(
          (WalletConnectPairingsState s) => s.error,
          'error',
          isA<StateError>(),
        ),
        WalletConnectPairingsState(
          pairings: <PairingInfo>[firstPairing],
          errorCount: 1,
        ),
      ],
    );

    late Completer<void> firstDeactivate;
    late Completer<void> secondDeactivate;
    blocTest<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      'increments errorCount for concurrent equal errors across topics',
      setUp: () {
        pairingsNotifier.value = <PairingInfo>[firstPairing, secondPairing];
        firstDeactivate = Completer<void>();
        secondDeactivate = Completer<void>();
        when(
          () => web3WalletService.deactivatePairing(topic: 'topic-1'),
        ).thenAnswer((_) => firstDeactivate.future);
        when(
          () => web3WalletService.deactivatePairing(topic: 'topic-2'),
        ).thenAnswer((_) => secondDeactivate.future);
      },
      build: buildBloc,
      act: (WalletConnectPairingsBloc bloc) async {
        bloc
          ..add(
            const WalletConnectPairingDeactivateRequested(topic: 'topic-1'),
          )
          ..add(
            const WalletConnectPairingDeactivateRequested(topic: 'topic-2'),
          );
        await Future<void>.delayed(Duration.zero);
        firstDeactivate.completeError('same-error');
        secondDeactivate.completeError('same-error');
        await Future<void>.delayed(Duration.zero);
      },
      errors: () => <Object>['same-error', 'same-error'],
      verify: (WalletConnectPairingsBloc bloc) {
        expect(bloc.state.errorCount, 2);
        expect(bloc.state.error, 'same-error');
        expect(bloc.state.deactivatingTopics, isEmpty);
      },
    );

    test('detaches listener on close', () async {
      final WalletConnectPairingsBloc bloc = buildBloc();
      // Accessing ChangeNotifier.hasListeners to verify listener cleanup.
      // ignore: invalid_use_of_protected_member
      expect(pairingsNotifier.hasListeners, isTrue);

      await bloc.close();

      // Verify the ChangeNotifier listener was detached on close.
      // ignore: invalid_use_of_protected_member
      expect(pairingsNotifier.hasListeners, isFalse);
    });
  });

  group('walletConnectMetadataUtils', () {
    test(
      'sanitizeWalletConnectHttpUrl rejects malformed and non-http URLs',
      () {
      expect(
        sanitizeWalletConnectHttpUrl('https://bridge.zenon.network/app'),
        'https://bridge.zenon.network/app',
      );
      expect(
        sanitizeWalletConnectHttpUrl('  http://localhost:3000  '),
        'http://localhost:3000',
      );
      expect(sanitizeWalletConnectHttpUrl('https://'), isNull);
      expect(sanitizeWalletConnectHttpUrl('http:foo'), isNull);
      expect(sanitizeWalletConnectHttpUrl('javascript:alert(1)'), isNull);
      expect(sanitizeWalletConnectHttpUrl(''), isNull);
      expect(sanitizeWalletConnectHttpUrl(null), isNull);
    });

    test('walletConnectDisplayValue replaces empty or null strings', () {
      expect(walletConnectDisplayValue('My dApp', 'Empty'), 'My dApp');
      expect(walletConnectDisplayValue('  ', 'Empty'), 'Empty');
      expect(walletConnectDisplayValue('null', 'Empty'), 'Empty');
      expect(walletConnectDisplayValue(null, 'Empty'), 'Empty');
    });
  });
}
