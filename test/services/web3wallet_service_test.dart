import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_core/crypto/i_crypto.dart';
import 'package:reown_core/pairing/i_expirer.dart';
import 'package:reown_core/pairing/i_pairing.dart';
import 'package:reown_core/relay_client/i_relay_client.dart';
import 'package:reown_core/store/i_store.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/wallet_connect_metadata_utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockWalletKit extends Mock implements ReownWalletKit {}

class _MockCore extends Mock implements IReownCore {}

class _MockRelayClient extends Mock implements IRelayClient {}

class _MockPairing extends Mock implements IPairing {}

class _MockPairingStore extends Mock implements IPairingStore {}

class _MockSessionStore extends Mock implements ISessions {}

class _MockCoreStorage extends Mock implements IStore<Map<String, dynamic>> {}

class _MockCrypto extends Mock implements ICrypto {}

class _MockExpirer extends Mock implements IExpirer {}

class _FakeNoMService extends Mock implements NoMService {}

SessionData _buildSession({required String topic, String chainId = 'zenon:1'}) {
  return SessionData(
    topic: topic,
    pairingTopic: 'pairing-$topic',
    relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
    expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    acknowledged: true,
    controller: 'controller-key',
    namespaces: <String, Namespace>{
      'zenon': Namespace(
        chains: <String>[chainId],
        accounts: <String>['$chainId:z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7'],
        methods: const <String>['znn_info', 'znn_sign', 'znn_send'],
        events: const <String>['chainIdChange', 'addressChange'],
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
    peer: const ConnectionMetadata(
      publicKey: 'peer-key',
      metadata: PairingMetadata(
        name: 'Test dApp',
        description: 'dApp',
        url: 'https://example.invalid',
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const JsonRpcResponse<dynamic>(id: 0));
    registerFallbackValue(const ReownSignError(code: 0, message: ''));
    registerFallbackValue(const SessionEventParams(name: '', data: null));
  });

  group('Web3WalletService', () {
    late _MockWalletKit walletKit;
    late _MockCore core;
    late _MockRelayClient relayClient;
    late _MockPairing pairing;
    late _MockPairingStore pairingStore;
    late _MockSessionStore sessionStore;
    late _MockCoreStorage coreStorage;
    late _MockCrypto crypto;
    late _MockExpirer expirer;
    late _FakeNoMService nomService;
    late Event<SessionRequestEvent> onSessionRequest;
    late Event<SessionProposalEvent> onSessionProposal;
    late Event<SessionConnect> onSessionConnect;
    late Event<SessionProposalErrorEvent> onSessionProposalError;
    late Event<SessionDelete> onSessionDelete;
    late Event<StoreSyncEvent> onPairingsSync;
    late Event<StoreSyncEvent> onSessionsSync;
    late Event<EventArgs> onRelayConnect;
    late Event<EventArgs> onRelayDisconnect;
    late Event<ErrorEvent> onRelayError;
    late Event<PairingEvent> onPairingCreate;
    late Event<PairingActivateEvent> onPairingActivate;
    late Event<PairingEvent> onPairingPing;
    late Event<PairingInvalidEvent> onPairingInvalid;
    late Event<PairingEvent> onPairingDelete;
    late Map<String, SessionData> activeSessions;
    late Map<String, SessionRequest> pendingRequests;
    late Map<String, String> previousAddressMap;
    late int previousChainId;

    Web3WalletService buildService() => Web3WalletService(
      walletKit: walletKit,
      chainResolver: (String _) => nomService,
    );

    setUp(() {
      previousAddressMap = Map<String, String>.from(kAddressLabelMap);
      previousChainId = getChainIdentifier();
      setChainIdentifier();
      kAddressLabelMap = <String, String>{
        'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7': 'Address 1',
      };

      walletKit = _MockWalletKit();
      core = _MockCore();
      relayClient = _MockRelayClient();
      pairing = _MockPairing();
      pairingStore = _MockPairingStore();
      sessionStore = _MockSessionStore();
      coreStorage = _MockCoreStorage();
      crypto = _MockCrypto();
      expirer = _MockExpirer();
      nomService = _FakeNoMService();

      onSessionRequest = Event<SessionRequestEvent>();
      onSessionProposal = Event<SessionProposalEvent>();
      onSessionConnect = Event<SessionConnect>();
      onSessionProposalError = Event<SessionProposalErrorEvent>();
      onSessionDelete = Event<SessionDelete>();
      onPairingsSync = Event<StoreSyncEvent>();
      onSessionsSync = Event<StoreSyncEvent>();
      onRelayConnect = Event<EventArgs>();
      onRelayDisconnect = Event<EventArgs>();
      onRelayError = Event<ErrorEvent>();
      onPairingCreate = Event<PairingEvent>();
      onPairingActivate = Event<PairingActivateEvent>();
      onPairingPing = Event<PairingEvent>();
      onPairingInvalid = Event<PairingInvalidEvent>();
      onPairingDelete = Event<PairingEvent>();

      activeSessions = <String, SessionData>{};
      pendingRequests = <String, SessionRequest>{};

      when(() => walletKit.core).thenReturn(core);
      when(() => core.relayClient).thenReturn(relayClient);
      when(() => core.pairing).thenReturn(pairing);
      when(() => core.storage).thenReturn(coreStorage);
      when(() => core.crypto).thenReturn(crypto);
      when(() => core.expirer).thenReturn(expirer);
      when(() => coreStorage.init()).thenAnswer((_) async {});
      when(() => coreStorage.has(any())).thenReturn(false);
      when(() => coreStorage.set(any(), any())).thenAnswer((_) async {});
      when(() => coreStorage.delete(any())).thenAnswer((_) async {});
      when(() => crypto.deleteKeyPair(any())).thenAnswer((_) async {});
      when(() => crypto.deleteSymKey(any())).thenAnswer((_) async {});
      when(() => expirer.delete(any())).thenAnswer((_) async {});
      when(
        () => relayClient.unsubscribe(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
      when(() => pairingStore.delete(any())).thenAnswer((_) async {});
      when(() => sessionStore.delete(any())).thenAnswer((_) async {});
      when(() => walletKit.pairings).thenReturn(pairingStore);
      when(() => walletKit.sessions).thenReturn(sessionStore);

      when(() => relayClient.onRelayClientConnect).thenReturn(onRelayConnect);
      when(
        () => relayClient.onRelayClientDisconnect,
      ).thenReturn(onRelayDisconnect);
      when(() => relayClient.onRelayClientError).thenReturn(onRelayError);

      when(() => pairing.onPairingCreate).thenReturn(onPairingCreate);
      when(() => pairing.onPairingActivate).thenReturn(onPairingActivate);
      when(() => pairing.onPairingPing).thenReturn(onPairingPing);
      when(() => pairing.onPairingInvalid).thenReturn(onPairingInvalid);
      when(() => pairing.onPairingDelete).thenReturn(onPairingDelete);

      when(() => pairingStore.onSync).thenReturn(onPairingsSync);
      when(() => sessionStore.onSync).thenReturn(onSessionsSync);
      when(() => pairingStore.getAll()).thenReturn(<PairingInfo>[]);
      when(
        () => sessionStore.getAll(),
      ).thenAnswer((_) => activeSessions.values.toList());

      when(() => walletKit.onSessionProposal).thenReturn(onSessionProposal);
      when(() => walletKit.onSessionConnect).thenReturn(onSessionConnect);
      when(() => walletKit.onSessionRequest).thenReturn(onSessionRequest);
      when(
        () => walletKit.onSessionProposalError,
      ).thenReturn(onSessionProposalError);
      when(() => walletKit.onSessionDelete).thenReturn(onSessionDelete);

      when(() => walletKit.init()).thenAnswer((_) async {});
      when(
        () => walletKit.getPendingSessionProposals(),
      ).thenReturn(<String, ProposalData>{});
      when(
        () => walletKit.getSessionsForPairing(
          pairingTopic: any(named: 'pairingTopic'),
        ),
      ).thenReturn(<String, SessionData>{});
      when(
        () => walletKit.disconnectSession(
          topic: any(named: 'topic'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => walletKit.rejectSession(
          id: any(named: 'id'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => pairing.disconnect(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
      when(
        () => walletKit.getActiveSessions(),
      ).thenAnswer((_) => Map<String, SessionData>.from(activeSessions));
      when(
        () => walletKit.getPendingSessionRequests(),
      ).thenAnswer((_) => Map<String, SessionRequest>.from(pendingRequests));
      when(
        () => walletKit.respondSessionRequest(
          topic: any(named: 'topic'),
          response: any(named: 'response'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => walletKit.emitSessionEvent(
          topic: any(named: 'topic'),
          chainId: any(named: 'chainId'),
          event: any(named: 'event'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      kAddressLabelMap = previousAddressMap;
      setChainIdentifier(chainIdentifier: previousChainId);
    });

    group('unsupportedRequiredNamespaceReason', () {
      test('accepts conforming Zenon required namespaces', () {
        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);

        expect(
          service.unsupportedRequiredNamespaceReason(
            <String, RequiredNamespace>{
              'zenon': const RequiredNamespace(
                chains: <String>['zenon:1'],
                methods: <String>['znn_info', 'znn_sign', 'znn_send'],
                events: <String>['addressChange', 'chainIdChange'],
              ),
            },
          ),
          isNull,
        );
      });

      test('rejects unsupported namespaces, chains, methods, and events', () {
        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);

        expect(
          service.unsupportedRequiredNamespaceReason(
            <String, RequiredNamespace>{
              'eip155': const RequiredNamespace(
                chains: <String>['eip155:1'],
                methods: <String>['eth_sendTransaction'],
                events: <String>[],
              ),
            },
          ),
          contains('Unsupported namespace'),
        );

        expect(
          service.unsupportedRequiredNamespaceReason(
            <String, RequiredNamespace>{
              'zenon': const RequiredNamespace(
                chains: <String>['zenon:3'],
                methods: <String>['znn_info'],
                events: <String>[],
              ),
            },
          ),
          contains('Unsupported chain(s)'),
        );

        expect(
          service.unsupportedRequiredNamespaceReason(
            <String, RequiredNamespace>{
              'zenon': const RequiredNamespace(
                chains: <String>['zenon:1'],
                methods: <String>['znn_unknown'],
                events: <String>[],
              ),
            },
          ),
          contains('Unsupported method(s)'),
        );

        expect(
          service.unsupportedRequiredNamespaceReason(
            <String, RequiredNamespace>{
              'zenon': const RequiredNamespace(
                chains: <String>['zenon:1'],
                methods: <String>['znn_info'],
                events: <String>['unknownEvent'],
              ),
            },
          ),
          contains('Unsupported event(s)'),
        );
      });
    });

    test('waits for in-flight init before handling live session request and '
        'deduplicates against startup pending backlog', () async {
      final SessionData session = _buildSession(topic: 'session-1');
      activeSessions['session-1'] = session;
      pendingRequests['77'] = const SessionRequest(
        id: 77,
        topic: 'session-1',
        method: 'znn_sign',
        chainId: 'zenon:1',
        params: 'hello',
        verifyContext: VerifyContext(
          origin: 'https://example.invalid',
          validation: Validation.VALID,
          verifyUrl: '',
        ),
      );

      final Completer<void> initGate = Completer<void>();
      when(() => walletKit.init()).thenAnswer((_) => initGate.future);
      when(
        () => nomService.handleZnnSign(
          'session-1',
          'hello',
          requestId: 77,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer((_) async => 'signed-hex');

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();

      final Future<void> initFuture = service.init();

      // Deliver the live event while init() is still in progress.
      onSessionRequest.broadcast(
        SessionRequestEvent(
          77,
          'session-1',
          'znn_sign',
          'zenon:1',
          'hello',
          TransportType.relay,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => walletKit.respondSessionRequest(
          topic: any(named: 'topic'),
          response: any(named: 'response'),
        ),
      );

      // Complete init(): both the waiting live listener and the startup
      // backlog drain see request 77, but it must only dispatch/respond once.
      initGate.complete();
      await initFuture;
      await Future<void>.delayed(Duration.zero);

      verify(
        () => nomService.handleZnnSign(
          'session-1',
          'hello',
          requestId: 77,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).called(1);
      final List<dynamic> captured = verify(
        () => walletKit.respondSessionRequest(
          topic: 'session-1',
          response: captureAny(named: 'response'),
        ),
      ).captured;
      expect(captured, hasLength(1));
      final JsonRpcResponse<dynamic> response =
          captured.single as JsonRpcResponse<dynamic>;
      expect(response.id, 77);
      expect(response.result, 'signed-hex');
    });

    test('skips stale session requests without an active session', () async {
      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      onSessionRequest.broadcast(
        SessionRequestEvent(
          88,
          'gone-topic',
          'znn_info',
          'zenon:1',
          null,
          TransportType.relay,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => nomService.handleZnnInfo(
          any(),
          any(),
          requestId: any(named: 'requestId'),
        ),
      );
      verifyNever(
        () => walletKit.respondSessionRequest(
          topic: any(named: 'topic'),
          response: any(named: 'response'),
        ),
      );
    });

    test(
      'propagates ReownCoreError code/message via respondSessionRequest',
      () async {
        activeSessions['session-1'] = _buildSession(topic: 'session-1');
        when(
          () => nomService.handleZnnInfo(
            'session-1',
            null,
            requestId: 91,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).thenAnswer(
          (_) => Future<dynamic>.error(
            const ReownCoreError(code: 9000, message: 'Wallet is locked'),
          ),
        );

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        onSessionRequest.broadcast(
          SessionRequestEvent(
            91,
            'session-1',
            'znn_info',
            'zenon:1',
            null,
            TransportType.relay,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final JsonRpcResponse<dynamic> response =
            verify(
                  () => walletKit.respondSessionRequest(
                    topic: 'session-1',
                    response: captureAny(named: 'response'),
                  ),
                ).captured.single
                as JsonRpcResponse<dynamic>;
        expect(response.id, 91);
        expect(response.error?.code, 9000);
        expect(response.error?.message, 'Wallet is locked');
      },
    );

    test('absorbs already-responded error without sending duplicate error '
        'response', () async {
      activeSessions['session-1'] = _buildSession(topic: 'session-1');
      when(
        () => nomService.handleZnnInfo(
          'session-1',
          null,
          requestId: 92,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'address': 'z1...'});
      when(
        () => walletKit.respondSessionRequest(
          topic: 'session-1',
          response: any(named: 'response'),
        ),
      ).thenThrow(Exception("Proposal id doesn't exist"));

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      onSessionRequest.broadcast(
        SessionRequestEvent(
          92,
          'session-1',
          'znn_info',
          'zenon:1',
          null,
          TransportType.relay,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verify(
        () => walletKit.respondSessionRequest(
          topic: 'session-1',
          response: any(named: 'response'),
        ),
      ).called(1);
    });

    test(
      'deactivatePairing and disconnectSession throw StateError before create '
      'and deactivatePairing rethrows ReownCoreError',
      () async {
        final Web3WalletService uncreated = Web3WalletService();
        addTearDown(uncreated.onDispose);
        await expectLater(
          uncreated.deactivatePairing(topic: 't1'),
          throwsStateError,
        );
        await expectLater(
          uncreated.disconnectSession(topic: 's1'),
          throwsStateError,
        );

        when(() => pairing.disconnect(topic: 'bad-topic')).thenAnswer(
          (_) => Future<void>.error(
            const ReownCoreError(code: 1001, message: 'No matching pairing'),
          ),
        );

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();

        await expectLater(
          service.deactivatePairing(topic: 'bad-topic'),
          throwsA(
            isA<ReownCoreError>().having(
              (ReownCoreError e) => e.code,
              'code',
              1001,
            ),
          ),
        );
      },
    );

    test(
      'emits address/chain events per session using each session chainId and '
      'isolates per-session failures',
      () async {
        activeSessions['session-mainnet'] = _buildSession(
          topic: 'session-mainnet',
        );
        activeSessions['session-testnet'] = _buildSession(
          topic: 'session-testnet',
          chainId: 'zenon:3',
        );

        when(
          () => walletKit.emitSessionEvent(
            topic: 'session-mainnet',
            chainId: 'zenon:1',
            event: any(named: 'event'),
          ),
        ).thenThrow(StateError('transient relay error'));

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        await service.emitAddressChangeEvent(
          'z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz',
        );

        verify(
          () => walletKit.emitSessionEvent(
            topic: 'session-mainnet',
            chainId: 'zenon:1',
            event: any(named: 'event'),
          ),
        ).called(1);
        verify(
          () => walletKit.emitSessionEvent(
            topic: 'session-testnet',
            chainId: 'zenon:3',
            event: any(named: 'event'),
          ),
        ).called(1);
      },
    );

    test('rejects proposals on unsupported custom active chain and disconnects '
        'stored sessions bound to unregistered chains on init', () async {
      setChainIdentifier(chainIdentifier: 42);
      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);

      expect(
        service.unsupportedRequiredNamespaceReason(<String, RequiredNamespace>{
          'zenon': const RequiredNamespace(
            chains: <String>['zenon:42'],
            methods: <String>['znn_info'],
            events: <String>[],
          ),
        }),
        contains('Unsupported active chain zenon:42'),
      );
      expect(
        service.unsupportedRequiredNamespaceReason(
          const <String, RequiredNamespace>{},
        ),
        contains('Unsupported active chain zenon:42'),
      );

      setChainIdentifier();
      activeSessions['good'] = _buildSession(topic: 'good');
      activeSessions['bad'] = _buildSession(topic: 'bad', chainId: 'zenon:42');

      service.create();
      await service.init();

      verify(
        () => walletKit.disconnectSession(
          topic: 'bad',
          reason: any(named: 'reason'),
        ),
      ).called(1);
      verifyNever(
        () => walletKit.disconnectSession(
          topic: 'good',
          reason: any(named: 'reason'),
        ),
      );

      // If a session with an unsupported chain somehow remains active,
      // incoming requests return UNSUPPORTED_CHAINS JSON-RPC error cleanly.
      onSessionRequest.broadcast(
        SessionRequestEvent(
          404,
          'bad',
          'znn_info',
          'zenon:42',
          null,
          TransportType.relay,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final JsonRpcResponse<dynamic> response =
          verify(
                () => walletKit.respondSessionRequest(
                  topic: 'bad',
                  response: captureAny(named: 'response'),
                ),
              ).captured.single
              as JsonRpcResponse<dynamic>;
      expect(response.id, 404);
      expect(
        response.error?.code,
        Errors.getSdkError(Errors.UNSUPPORTED_CHAINS).code,
      );
    });

    test('pair() preserves active reusable pairings and pairings with pending '
        'proposals while cleaning up inactive or expired orphans', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final PairingInfo reusableActive = PairingInfo(
        topic: 'active-reusable',
        expiry: now + 3600,
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        active: true,
      );
      final PairingInfo pendingProposalPairing = PairingInfo(
        topic: 'pending-proposal',
        expiry: now + 3600,
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        active: false,
      );
      final PairingInfo inactiveOrphan = PairingInfo(
        topic: 'inactive-orphan',
        expiry: now + 3600,
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        active: false,
      );
      final PairingInfo expiredActive = PairingInfo(
        topic: 'expired-active',
        expiry: now - 60,
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        active: true,
      );
      final PairingInfo newlyPaired = PairingInfo(
        topic: 'new-pairing',
        expiry: now + 3600,
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        active: false,
      );

      when(() => pairingStore.getAll()).thenReturn(<PairingInfo>[
        reusableActive,
        pendingProposalPairing,
        inactiveOrphan,
        expiredActive,
      ]);
      when(() => walletKit.getPendingSessionProposals()).thenReturn(
        <String, ProposalData>{
          '10': ProposalData(
            id: 10,
            expiry: now + 300,
            relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
            proposer: const ConnectionMetadata(
              publicKey: 'peer',
              metadata: PairingMetadata(
                name: 'dApp',
                description: 'desc',
                url: 'https://example.invalid',
              ),
            ),
            requiredNamespaces: const <String, RequiredNamespace>{},
            optionalNamespaces: const <String, RequiredNamespace>{},
            pairingTopic: 'pending-proposal',
          ),
        },
      );
      final Uri uri = Uri.parse('wc:abcdef@2?relay-protocol=irn&symKey=123456');
      when(() => walletKit.pair(uri: uri)).thenAnswer((_) async => newlyPaired);

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      await service.pair(uri);

      verifyNever(() => pairing.disconnect(topic: 'active-reusable'));
      verifyNever(() => pairing.disconnect(topic: 'pending-proposal'));
      verify(() => pairing.disconnect(topic: 'inactive-orphan')).called(1);
      verify(() => pairing.disconnect(topic: 'expired-active')).called(1);
    });

    test(
      'disconnectEverything called while init is pending completes without '
      'blocking and wipes persisted sessions and pairings once init finishes',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        activeSessions['persisted-s1'] = _buildSession(topic: 'persisted-s1');
        when(() => pairingStore.getAll()).thenReturn(<PairingInfo>[
          PairingInfo(
            topic: 'persisted-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        ]);

        final Completer<void> initGate = Completer<void>();
        when(() => walletKit.init()).thenAnswer((_) => initGate.future);

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();

        final Future<void> initFuture = service.init();

        // Must complete promptly while init() is still blocked.
        await service.disconnectEverything().timeout(
          const Duration(seconds: 1),
        );

        verifyNever(
          () => walletKit.disconnectSession(
            topic: 'persisted-s1',
            reason: any(named: 'reason'),
          ),
        );

        initGate.complete();
        await initFuture;

        verify(
          () => walletKit.disconnectSession(
            topic: 'persisted-s1',
            reason: any(named: 'reason'),
          ),
        ).called(1);
        verify(() => pairing.disconnect(topic: 'persisted-p1')).called(1);
      },
    );

    test('retries pending requests on relay reconnect after error-response '
        'send failure', () async {
      activeSessions['session-1'] = _buildSession(topic: 'session-1');
      pendingRequests['301'] = const SessionRequest(
        id: 301,
        topic: 'session-1',
        method: 'znn_info',
        chainId: 'zenon:1',
        params: null,
        verifyContext: VerifyContext(
          origin: 'https://example.invalid',
          validation: Validation.VALID,
          verifyUrl: '',
        ),
      );
      when(
        () => nomService.handleZnnInfo(
          'session-1',
          null,
          requestId: 301,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer(
        (_) => Future<dynamic>.error(
          const ReownCoreError(code: 9000, message: 'Wallet is locked'),
        ),
      );

      int respondAttempts = 0;
      when(
        () => walletKit.respondSessionRequest(
          topic: 'session-1',
          response: any(named: 'response'),
        ),
      ).thenAnswer((_) async {
        respondAttempts++;
        if (respondAttempts == 1) {
          throw StateError('relay disconnected');
        }
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();
      await Future<void>.delayed(Duration.zero);

      expect(respondAttempts, 1);

      // Relay reconnect triggers backlog retry, delivering ONLY the cached
      // error response without re-running handleZnnInfo.
      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      expect(respondAttempts, 2);
      verify(
        () => nomService.handleZnnInfo(
          'session-1',
          null,
          requestId: 301,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).called(1);
    });

    test(
      'retries cached znn_send success response on relay reconnect without '
      're-executing handleZnnSend or converting success into an error',
      () async {
        final AccountBlockTemplate sentBlock = AccountBlockTemplate.send(
          Address.parse('z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz'),
          znnZts,
          BigInt.from(25),
        );
        activeSessions['session-1'] = _buildSession(topic: 'session-1');
        pendingRequests['405'] = const SessionRequest(
          id: 405,
          topic: 'session-1',
          method: 'znn_send',
          chainId: 'zenon:1',
          params: <String, dynamic>{},
          verifyContext: VerifyContext(
            origin: 'https://example.invalid',
            validation: Validation.VALID,
            verifyUrl: '',
          ),
        );
        when(
          () => nomService.handleZnnSend(
            'session-1',
            any(),
            requestId: 405,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).thenAnswer((_) async => sentBlock);

        int respondAttempts = 0;
        final List<JsonRpcResponse<dynamic>> sentResponses =
            <JsonRpcResponse<dynamic>>[];
        when(
          () => walletKit.respondSessionRequest(
            topic: 'session-1',
            response: any(named: 'response'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final JsonRpcResponse<dynamic> response =
              invocation.namedArguments[#response] as JsonRpcResponse<dynamic>;
          sentResponses.add(response);
          respondAttempts++;
          if (respondAttempts == 1) {
            throw StateError('No internet connection');
          }
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();
        await Future<void>.delayed(Duration.zero);

        // Initial delivery failed offline: must NOT have sent an error response
        // for a succeeded transfer.
        expect(respondAttempts, 1);
        expect(sentResponses.single.error, isNull);
        expect(sentResponses.single.result, sentBlock);

        // Relay reconnect resends the cached success response without
        // re-invoking handleZnnSend.
        onRelayConnect.broadcast(EventArgs());
        await Future<void>.delayed(Duration.zero);

        expect(respondAttempts, 2);
        expect(sentResponses.last.error, isNull);
        expect(sentResponses.last.result, sentBlock);
        verify(
          () => nomService.handleZnnSend(
            'session-1',
            any(),
            requestId: 405,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).called(1);
      },
    );

    test(
      'logs WARNING with request id and block hash when side-effecting '
      'znn_send fails delivery with EXPIRED or stale session error',
      () async {
        final List<LogRecord> warnings = <LogRecord>[];
        final StreamSubscription<LogRecord> sub = Logger('WalletConnectService')
            .onRecord
            .listen((LogRecord record) {
              if (record.level >= Level.WARNING) {
                warnings.add(record);
              }
            });
        addTearDown(sub.cancel);

        final AccountBlockTemplate sentBlock = AccountBlockTemplate.send(
          Address.parse('z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz'),
          znnZts,
          BigInt.from(15),
        );
        activeSessions['session-1'] = _buildSession(topic: 'session-1');
        when(
          () => nomService.handleZnnSend(
            'session-1',
            any(),
            requestId: 506,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).thenAnswer((_) async => sentBlock);
        when(
          () => walletKit.respondSessionRequest(
            topic: 'session-1',
            response: any(named: 'response'),
          ),
        ).thenThrow(Exception('Request expired: pending request id: 506'));

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        onSessionRequest.broadcast(
          SessionRequestEvent(
            506,
            'session-1',
            'znn_send',
            'zenon:1',
            <String, dynamic>{},
            TransportType.relay,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          warnings.any(
            (LogRecord r) =>
                r.message.contains('id=506') &&
                r.message.contains('blockHash=${sentBlock.hash}'),
          ),
          isTrue,
        );
      },
    );

    test('logs WARNING with request id and block hash when a side-effecting '
        'znn_send expires before respondSessionRequest completes', () async {
      final List<LogRecord> warnings = <LogRecord>[];
      final StreamSubscription<LogRecord> sub = Logger('WalletConnectService')
          .onRecord
          .listen((LogRecord record) {
            if (record.level >= Level.WARNING) {
              warnings.add(record);
            }
          });
      addTearDown(sub.cancel);

      final AccountBlockTemplate sentBlock = AccountBlockTemplate.send(
        Address.parse('z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz'),
        znnZts,
        BigInt.from(10),
      );
      activeSessions['session-1'] = _buildSession(topic: 'session-1');
      when(
        () => nomService.handleZnnSend(
          'session-1',
          any(),
          requestId: 505,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer((_) async => sentBlock);
      when(
        () => walletKit.respondSessionRequest(
          topic: 'session-1',
          response: any(named: 'response'),
        ),
      ).thenThrow(Exception("No matching key. proposal id doesn't exist: 505"));

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      onSessionRequest.broadcast(
        SessionRequestEvent(
          505,
          'session-1',
          'znn_send',
          'zenon:1',
          <String, dynamic>{},
          TransportType.relay,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        warnings.any(
          (LogRecord r) =>
              r.message.contains('id=505') &&
              r.message.contains('blockHash=${sentBlock.hash}'),
        ),
        isTrue,
      );
    });

    test('blocks session requests flagged as scam by VerifyContext before '
        'dispatching to NoMService', () async {
      activeSessions['session-1'] = _buildSession(topic: 'session-1');
      pendingRequests['606'] = const SessionRequest(
        id: 606,
        topic: 'session-1',
        method: 'znn_sign',
        chainId: 'zenon:1',
        params: 'hello',
        verifyContext: VerifyContext(
          origin: 'https://phishing.invalid',
          validation: Validation.SCAM,
          verifyUrl: 'https://verify.walletconnect.org',
          isScam: true,
        ),
      );

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => nomService.handleZnnSign(
          any(),
          any(),
          requestId: any(named: 'requestId'),
          verifyContext: any(named: 'verifyContext'),
        ),
      );
      final JsonRpcResponse<dynamic> response =
          verify(
                () => walletKit.respondSessionRequest(
                  topic: 'session-1',
                  response: captureAny(named: 'response'),
                ),
              ).captured.single
              as JsonRpcResponse<dynamic>;
      expect(response.id, 606);
      expect(response.error?.message, contains('scam'));
    });

    group('VerifyContext classification helpers', () {
      test('classifies VALID, INVALID, UNKNOWN, null, and SCAM contexts', () {
        expect(
          describeWalletConnectVerifyContext(null).severity,
          WalletConnectVerifySeverity.unverified,
        );
        expect(
          describeWalletConnectVerifyContext(
            const VerifyContext(
              origin: 'https://app.zenon.org',
              validation: Validation.VALID,
              verifyUrl: '',
            ),
          ).severity,
          WalletConnectVerifySeverity.verified,
        );
        expect(
          describeWalletConnectVerifyContext(
            const VerifyContext(
              origin: 'https://spoof.invalid',
              validation: Validation.INVALID,
              verifyUrl: '',
            ),
          ).severity,
          WalletConnectVerifySeverity.invalid,
        );
        expect(
          isWalletConnectVerifyScam(
            const VerifyContext(
              origin: 'https://evil.invalid',
              validation: Validation.UNKNOWN,
              verifyUrl: '',
              isScam: true,
            ),
          ),
          isTrue,
        );
      });
    });

    test(
      'disconnectEverything persists reset marker across restart and deletes '
      'local session/pairing records when relay disconnect fails offline',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        when(() => coreStorage.has(any())).thenAnswer(
          (Invocation i) =>
              persistedStorage.containsKey(i.positionalArguments[0]),
        );
        when(() => coreStorage.set(any(), any())).thenAnswer((
          Invocation i,
        ) async {
          persistedStorage[i.positionalArguments[0] as String] =
              i.positionalArguments[1] as Map<String, dynamic>;
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          persistedStorage.remove(i.positionalArguments[0] as String);
        });

        activeSessions['offline-s1'] = _buildSession(topic: 'offline-s1');
        when(() => pairingStore.getAll()).thenReturn(<PairingInfo>[
          PairingInfo(
            topic: 'offline-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        ]);
        when(
          () => walletKit.disconnectSession(
            topic: 'offline-s1',
            reason: any(named: 'reason'),
          ),
        ).thenThrow(StateError('No internet connection'));
        when(
          () => pairing.disconnect(topic: 'offline-p1'),
        ).thenThrow(StateError('No internet connection'));

        // Launch 1: wallet reset runs before init() ever runs, then exits.
        final Web3WalletService launch1 = buildService();
        addTearDown(launch1.onDispose);
        launch1.create();
        await launch1.disconnectEverything();
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isTrue,
        );

        // Launch 2: fresh service instance initializes offline; persisted reset
        // marker triggers local deletion of sessions & pairings and clears
        // marker afterwards.
        final Web3WalletService launch2 = buildService();
        addTearDown(launch2.onDispose);
        launch2.create();
        await launch2.init();

        verify(() => sessionStore.delete('offline-s1')).called(1);
        verify(() => crypto.deleteKeyPair('self-key')).called(1);
        verify(() => crypto.deleteSymKey('offline-s1')).called(1);
        verify(() => expirer.delete('offline-s1')).called(1);
        verify(() => pairingStore.delete('offline-p1')).called(1);
        verify(() => crypto.deleteSymKey('offline-p1')).called(1);
        verify(() => expirer.delete('offline-p1')).called(1);
        verify(() => relayClient.unsubscribe(topic: 'offline-s1')).called(1);
        verify(() => relayClient.unsubscribe(topic: 'offline-p1')).called(1);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );
  });
}
