import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_core/crypto/i_crypto.dart';
import 'package:reown_core/pairing/i_expirer.dart';
import 'package:reown_core/pairing/i_pairing.dart';
import 'package:reown_core/relay_client/i_relay_client.dart';
import 'package:reown_core/store/i_generic_store.dart';
import 'package:reown_core/store/i_store.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
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

class _MockKeyChainStore extends Mock implements IGenericStore<String> {}

class _MockExpirer extends Mock implements IExpirer {}

class _FakeNoMService extends Mock implements NoMService {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

SessionData _buildSession({
  required String topic,
  String chainId = 'zenon:1',
  String selfPublicKey = 'self-key',
}) {
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
    self: ConnectionMetadata(
      publicKey: selfPublicKey,
      metadata: const PairingMetadata(
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
    registerFallbackValue(Uri());
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
    late _MockKeyChainStore keyChainStore;
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
      keyChainStore = _MockKeyChainStore();
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
      when(() => coreStorage.get(any())).thenReturn(null);
      when(() => coreStorage.set(any(), any())).thenAnswer((_) async {});
      when(() => coreStorage.delete(any())).thenAnswer((_) async {});
      when(() => crypto.keyChain).thenReturn(keyChainStore);
      when(() => crypto.deleteKeyPair(any())).thenAnswer((_) async {});
      when(() => crypto.deleteSymKey(any())).thenAnswer((_) async {});
      when(keyChainStore.persist).thenAnswer((_) async {});
      when(() => expirer.delete(any())).thenAnswer((_) async {});
      when(expirer.persist).thenAnswer((_) async {});
      when(
        () => relayClient.unsubscribe(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
      when(() => pairingStore.delete(any())).thenAnswer((_) async {});
      when(() => pairingStore.persist()).thenAnswer((_) async {});
      when(() => sessionStore.delete(any())).thenAnswer((_) async {});
      when(() => sessionStore.persist()).thenAnswer((_) async {});
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
      'local session/pairing records verified on cold restore',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Map<String, SessionData> persistedSessions =
            <String, SessionData>{
              'offline-s1': _buildSession(topic: 'offline-s1'),
            };
        final Map<String, PairingInfo> persistedPairings =
            <String, PairingInfo>{
              'offline-p1': PairingInfo(
                topic: 'offline-p1',
                expiry: now + 3600,
                relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
                active: true,
              ),
            };

        ({
          Web3WalletService service,
          _MockSessionStore sessionStore,
          _MockPairingStore pairingStore,
          _MockCrypto crypto,
          _MockExpirer expirer,
          _MockRelayClient relayClient,
        })
        createColdLaunch({required bool offline}) {
          final _MockWalletKit kit = _MockWalletKit();
          final _MockCore c = _MockCore();
          final _MockRelayClient rc = _MockRelayClient();
          final _MockPairing p = _MockPairing();
          final _MockPairingStore ps = _MockPairingStore();
          final _MockSessionStore ss = _MockSessionStore();
          final _MockCoreStorage cs = _MockCoreStorage();
          final _MockCrypto cr = _MockCrypto();
          final _MockKeyChainStore kc = _MockKeyChainStore();
          final _MockExpirer ex = _MockExpirer();

          when(() => kit.core).thenReturn(c);
          when(() => c.relayClient).thenReturn(rc);
          when(() => c.pairing).thenReturn(p);
          when(() => c.storage).thenReturn(cs);
          when(() => c.crypto).thenReturn(cr);
          when(() => c.expirer).thenReturn(ex);
          when(() => kit.pairings).thenReturn(ps);
          when(() => kit.sessions).thenReturn(ss);
          when(kit.init).thenAnswer((_) async {});
          when(
            kit.getActiveSessions,
          ).thenAnswer((_) => Map<String, SessionData>.from(persistedSessions));
          when(
            kit.getPendingSessionRequests,
          ).thenReturn(const <String, SessionRequest>{});
          when(
            kit.getPendingSessionProposals,
          ).thenReturn(const <String, ProposalData>{});
          when(
            () => kit.getSessionsForPairing(
              pairingTopic: any(named: 'pairingTopic'),
            ),
          ).thenReturn(const <String, SessionData>{});

          when(() => rc.onRelayClientConnect).thenReturn(Event<EventArgs>());
          when(() => rc.onRelayClientDisconnect).thenReturn(Event<EventArgs>());
          when(() => rc.onRelayClientError).thenReturn(Event<ErrorEvent>());
          when(() => p.onPairingCreate).thenReturn(Event<PairingEvent>());
          when(
            () => p.onPairingActivate,
          ).thenReturn(Event<PairingActivateEvent>());
          when(() => p.onPairingPing).thenReturn(Event<PairingEvent>());
          when(
            () => p.onPairingInvalid,
          ).thenReturn(Event<PairingInvalidEvent>());
          when(() => p.onPairingDelete).thenReturn(Event<PairingEvent>());
          when(() => ps.onSync).thenReturn(Event<StoreSyncEvent>());
          when(() => ss.onSync).thenReturn(Event<StoreSyncEvent>());
          when(
            () => kit.onSessionProposal,
          ).thenReturn(Event<SessionProposalEvent>());
          when(() => kit.onSessionConnect).thenReturn(Event<SessionConnect>());
          when(
            () => kit.onSessionRequest,
          ).thenReturn(Event<SessionRequestEvent>());
          when(
            () => kit.onSessionProposalError,
          ).thenReturn(Event<SessionProposalErrorEvent>());
          when(() => kit.onSessionDelete).thenReturn(Event<SessionDelete>());

          when(cs.init).thenAnswer((_) async {});
          when(() => cs.has(any())).thenAnswer(
            (Invocation i) =>
                persistedStorage.containsKey(i.positionalArguments[0]),
          );
          when(() => cs.get(any())).thenAnswer(
            (Invocation i) => persistedStorage[i.positionalArguments[0]],
          );
          when(() => cs.set(any(), any())).thenAnswer((Invocation i) async {
            persistedStorage[i.positionalArguments[0]
                as String] = Map<String, dynamic>.from(
              i.positionalArguments[1] as Map<String, dynamic>,
            );
          });
          when(() => cs.delete(any())).thenAnswer((Invocation i) async {
            persistedStorage.remove(i.positionalArguments[0] as String);
          });

          when(ss.getAll).thenAnswer((_) => persistedSessions.values.toList());
          when(() => ss.delete(any())).thenAnswer((Invocation i) async {
            persistedSessions.remove(i.positionalArguments[0] as String);
          });
          when(ss.persist).thenAnswer((_) async {});

          when(ps.getAll).thenAnswer((_) => persistedPairings.values.toList());
          when(() => ps.delete(any())).thenAnswer((Invocation i) async {
            persistedPairings.remove(i.positionalArguments[0] as String);
          });
          when(ps.persist).thenAnswer((_) async {});

          when(() => cr.keyChain).thenReturn(kc);
          when(() => cr.deleteKeyPair(any())).thenAnswer((_) async {});
          when(() => cr.deleteSymKey(any())).thenAnswer((_) async {});
          when(kc.persist).thenAnswer((_) async {});
          when(() => ex.delete(any())).thenAnswer((_) async {});
          when(ex.persist).thenAnswer((_) async {});
          when(
            () => rc.unsubscribe(topic: any(named: 'topic')),
          ).thenAnswer((_) async {});

          if (offline) {
            when(
              () => kit.disconnectSession(
                topic: any(named: 'topic'),
                reason: any(named: 'reason'),
              ),
            ).thenThrow(StateError('No internet connection'));
            when(
              () => p.disconnect(topic: any(named: 'topic')),
            ).thenThrow(StateError('No internet connection'));
          } else {
            when(
              () => kit.disconnectSession(
                topic: any(named: 'topic'),
                reason: any(named: 'reason'),
              ),
            ).thenAnswer((_) async {});
            when(
              () => p.disconnect(topic: any(named: 'topic')),
            ).thenAnswer((_) async {});
          }

          return (
            service: Web3WalletService(
              walletKit: kit,
              chainResolver: (String _) => nomService,
            ),
            sessionStore: ss,
            pairingStore: ps,
            crypto: cr,
            expirer: ex,
            relayClient: rc,
          );
        }

        // Launch 1: wallet reset runs before init() ever runs, then disposes.
        final ({
          Web3WalletService service,
          _MockSessionStore sessionStore,
          _MockPairingStore pairingStore,
          _MockCrypto crypto,
          _MockExpirer expirer,
          _MockRelayClient relayClient,
        })
        launch1 = createColdLaunch(offline: true);
        launch1.service.create();
        await launch1.service.disconnectEverything();
        await launch1.service.onDispose();
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isTrue,
        );

        // Launch 2: fresh clients & stores initialize offline; persisted reset
        // marker purges sessions & pairings from persistent state and clears
        // the marker.
        final ({
          Web3WalletService service,
          _MockSessionStore sessionStore,
          _MockPairingStore pairingStore,
          _MockCrypto crypto,
          _MockExpirer expirer,
          _MockRelayClient relayClient,
        })
        launch2 = createColdLaunch(offline: true);
        launch2.service.create();
        await launch2.service.init();

        verify(() => launch2.sessionStore.delete('offline-s1')).called(1);
        verify(() => launch2.crypto.deleteKeyPair('self-key')).called(1);
        verify(() => launch2.crypto.deleteSymKey('offline-s1')).called(1);
        verify(() => launch2.expirer.delete('offline-s1')).called(1);
        verify(() => launch2.pairingStore.delete('offline-p1')).called(1);
        verify(() => launch2.crypto.deleteSymKey('offline-p1')).called(1);
        verify(() => launch2.expirer.delete('offline-p1')).called(1);
        verify(
          () => launch2.relayClient.unsubscribe(topic: 'offline-s1'),
        ).called(1);
        verify(
          () => launch2.relayClient.unsubscribe(topic: 'offline-p1'),
        ).called(1);
        expect(persistedSessions, isEmpty);
        expect(persistedPairings, isEmpty);
        expect(launch2.service.sessions.value, isEmpty);
        expect(launch2.service.pairings.value, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
        await launch2.service.onDispose();

        // Launch 3: fresh cold restore sees neither old session nor pairing.
        final ({
          Web3WalletService service,
          _MockSessionStore sessionStore,
          _MockPairingStore pairingStore,
          _MockCrypto crypto,
          _MockExpirer expirer,
          _MockRelayClient relayClient,
        })
        launch3 = createColdLaunch(offline: false);
        addTearDown(launch3.service.onDispose);
        launch3.service.create();
        await launch3.service.init();

        expect(launch3.service.sessions.value, isEmpty);
        expect(launch3.service.pairings.value, isEmpty);
        expect(launch3.service.getActiveSessions(), isEmpty);
      },
    );

    test('gates relay-reconnect request draining while a startup reset is '
        'in progress', () async {
      activeSessions['reset-s1'] = _buildSession(topic: 'reset-s1');
      pendingRequests['901'] = const SessionRequest(
        id: 901,
        topic: 'reset-s1',
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
        () => coreStorage.has(Web3WalletService.pendingResetStorageKey),
      ).thenReturn(true);
      when(
        () => coreStorage.get(Web3WalletService.pendingResetStorageKey),
      ).thenReturn(<String, dynamic>{'pending': true, 'fullReset': true});

      final Completer<void> disconnectGate = Completer<void>();
      when(
        () => walletKit.disconnectSession(
          topic: 'reset-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        await disconnectGate.future;
        activeSessions.remove('reset-s1');
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();

      final Future<void> initFuture = service.init();
      await Future<void>.delayed(Duration.zero);

      // Relay reconnect fires while disconnectEverything() is awaiting
      // disconnectSession: pending request 901 must NOT be dispatched.
      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => nomService.handleZnnInfo(
          any(),
          any(),
          requestId: any(named: 'requestId'),
          verifyContext: any(named: 'verifyContext'),
        ),
      );

      disconnectGate.complete();
      await initFuture;
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => nomService.handleZnnInfo(
          any(),
          any(),
          requestId: any(named: 'requestId'),
          verifyContext: any(named: 'verifyContext'),
        ),
      );

      // Once the reset completes and clears its marker, a later session's
      // pending request drains normally on reconnect.
      when(
        () => coreStorage.has(Web3WalletService.pendingResetStorageKey),
      ).thenReturn(false);
      activeSessions['new-s2'] = _buildSession(topic: 'new-s2');
      pendingRequests['902'] = const SessionRequest(
        id: 902,
        topic: 'new-s2',
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
          'new-s2',
          null,
          requestId: 902,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'address': 'z1...'});

      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      verify(
        () => nomService.handleZnnInfo(
          'new-s2',
          null,
          requestId: 902,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).called(1);
    });

    test('retains reset marker with topic and key identifiers when local key '
        'cleanup fails after session record deletion, and finishes cleanup on '
        'restart', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['partial-s1'] = _buildSession(topic: 'partial-s1');
      when(() => sessionStore.delete('partial-s1')).thenAnswer((_) async {
        activeSessions.remove('partial-s1');
      });
      when(
        () => walletKit.disconnectSession(
          topic: 'partial-s1',
          reason: any(named: 'reason'),
        ),
      ).thenThrow(StateError('offline'));

      bool failKeyPairDelete = true;
      when(() => crypto.deleteKeyPair('self-key')).thenAnswer((_) async {
        if (failKeyPairDelete) {
          throw StateError('keychain busy');
        }
      });

      // Attempt 1: session record is removed, but deleteKeyPair fails.
      // Marker must NOT be cleared and must retain topic + publicKey.
      final Web3WalletService launch1 = buildService()..create();
      await launch1.init();

      expect(activeSessions, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isTrue,
      );
      final Map<String, dynamic> retainedMarker =
          persistedStorage[Web3WalletService.pendingResetStorageKey]!;
      expect(retainedMarker['fullReset'], isFalse);
      expect(
        retainedMarker['pendingSessions'],
        equals(<Map<String, String>>[
          <String, String>{'topic': 'partial-s1', 'publicKey': 'self-key'},
        ]),
      );
      await expectLater(
        launch1.pair(Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def')),
        throwsStateError,
      );
      verifyNever(() => walletKit.pair(uri: any(named: 'uri')));
      verify(() => crypto.deleteKeyPair('self-key')).called(2);
      await launch1.onDispose();

      // Attempt 2: fresh launch with empty live session store still retries
      // key cleanup using the persisted identifiers, then clears the marker.
      failKeyPairDelete = false;
      final Web3WalletService launch2 = buildService();
      addTearDown(launch2.onDispose);
      launch2.create();
      await launch2.init();

      verify(() => crypto.deleteKeyPair('self-key')).called(1);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test('disconnectEverything propagates marker write failure before init '
        'instead of succeeding silently', () async {
      when(
        () => coreStorage.set(Web3WalletService.pendingResetStorageKey, any()),
      ).thenThrow(StateError('disk full'));

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();

      await expectLater(service.disconnectEverything(), throwsStateError);
    });

    test('blocks new pairings while pending reset marker deletion fails and '
        'allows pairing once marker removal succeeds', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      bool failMarkerDelete = true;
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        if (failMarkerDelete) {
          throw StateError('marker delete failed');
        }
        persistedStorage.remove(i.positionalArguments[0] as String);
      });
      final PairingInfo newPairing = PairingInfo(
        topic: 'fresh-pairing',
        expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        active: false,
      );
      when(
        () => walletKit.pair(uri: any(named: 'uri')),
      ).thenAnswer((_) async => newPairing);

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Marker delete failed during startup reset -> pair() must refuse so
      // the stale marker cannot wipe a newly created pairing on relaunch.
      await expectLater(
        service.pair(Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def')),
        throwsStateError,
      );
      verifyNever(() => walletKit.pair(uri: any(named: 'uri')));

      // Once marker deletion succeeds, pair() clears the marker and proceeds.
      failMarkerDelete = false;
      final PairingInfo paired = await service.pair(
        Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def'),
      );
      expect(paired.topic, 'fresh-pairing');
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    group('buildApprovedNamespaces', () {
      ProposalData buildProposal({
        Map<String, RequiredNamespace> requiredNamespaces =
            const <String, RequiredNamespace>{},
        Map<String, RequiredNamespace> optionalNamespaces =
            const <String, RequiredNamespace>{},
      }) {
        return ProposalData(
          id: 1,
          expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
          relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
          proposer: const ConnectionMetadata(
            publicKey: 'peer-key',
            metadata: PairingMetadata(
              name: 'Test dApp',
              description: 'dApp',
              url: 'https://example.invalid',
            ),
          ),
          requiredNamespaces: requiredNamespaces,
          optionalNamespaces: optionalNamespaces,
          generatedNamespaces: const <String, Namespace>{},
          pairingTopic: 'pairing-1',
        );
      }

      test('grants only the requested subset of methods and events', () {
        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);

        final Map<String, Namespace> approved = service.buildApprovedNamespaces(
          buildProposal(
            requiredNamespaces: <String, RequiredNamespace>{
              'zenon': const RequiredNamespace(
                chains: <String>['zenon:1'],
                methods: <String>['znn_info'],
                events: <String>['addressChange'],
              ),
            },
          ),
        );

        final Namespace? zenon = approved['zenon'];
        expect(zenon, isNotNull);
        expect(zenon!.chains, equals(<String>['zenon:1']));
        expect(zenon.methods, equals(<String>['znn_info']));
        expect(zenon.events, equals(<String>['addressChange']));
      });

      test(
        'includes supported optional permissions for active chain and filters '
        'unsupported optional namespaces, chains, methods, and events',
        () {
          final Web3WalletService service = buildService();
          addTearDown(service.onDispose);

          final Map<String, Namespace> approved = service
              .buildApprovedNamespaces(
                buildProposal(
                  requiredNamespaces: <String, RequiredNamespace>{
                    'zenon': const RequiredNamespace(
                      chains: <String>['zenon:1'],
                      methods: <String>['znn_info'],
                      events: <String>[],
                    ),
                  },
                  optionalNamespaces: <String, RequiredNamespace>{
                    'zenon': const RequiredNamespace(
                      chains: <String>['zenon:1'],
                      methods: <String>['znn_sign', 'znn_unsupported'],
                      events: <String>['chainIdChange', 'unsupportedEvent'],
                    ),
                    'zenon:3': const RequiredNamespace(
                      chains: <String>['zenon:3'],
                      methods: <String>['znn_send'],
                      events: <String>['addressChange'],
                    ),
                    'eip155': const RequiredNamespace(
                      chains: <String>['eip155:1'],
                      methods: <String>['eth_sendTransaction'],
                      events: <String>['accountsChanged'],
                    ),
                  },
                ),
              );

          expect(approved.keys, equals(<String>['zenon']));
          expect(
            approved['zenon']!.methods,
            equals(<String>['znn_info', 'znn_sign']),
          );
          expect(approved['zenon']!.events, equals(<String>['chainIdChange']));
        },
      );

      test('falls back to full supported Zenon capabilities when proposal '
          'declares no matching Zenon namespaces', () {
        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);

        final Map<String, Namespace> approved = service.buildApprovedNamespaces(
          buildProposal(),
        );

        expect(
          approved['zenon']!.methods,
          containsAll(<String>['znn_sign', 'znn_info', 'znn_send']),
        );
        expect(
          approved['zenon']!.events,
          containsAll(<String>['chainIdChange', 'addressChange']),
        );
      });

      test('does not grant full Zenon methods when proposal only declares '
          'non-active-chain or foreign optional namespaces', () {
        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);

        final Map<String, Namespace> approved = service.buildApprovedNamespaces(
          buildProposal(
            optionalNamespaces: <String, RequiredNamespace>{
              'zenon:3': const RequiredNamespace(
                chains: <String>['zenon:3'],
                methods: <String>['znn_send'],
                events: <String>['addressChange'],
              ),
              'eip155': const RequiredNamespace(
                chains: <String>['eip155:1'],
                methods: <String>['eth_sendTransaction'],
                events: <String>[],
              ),
            },
          ),
        );

        expect(approved['zenon']!.methods, isEmpty);
        expect(approved['zenon']!.events, isEmpty);
      });
    });

    test('overlapping disconnectEverything during startup reset does not leave '
        'request handling permanently gated', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['reset-s1'] = _buildSession(topic: 'reset-s1');
      final Completer<void> disconnectGate = Completer<void>();
      when(
        () => walletKit.disconnectSession(
          topic: 'reset-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        await disconnectGate.future;
        activeSessions.remove('reset-s1');
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();

      final Future<void> initFuture = service.init();
      await Future<void>.delayed(Duration.zero);

      // Trigger an overlapping reset while startup reset is in flight.
      final Future<void> overlappingReset = service.disconnectEverything();
      await Future<void>.delayed(Duration.zero);

      disconnectGate.complete();
      await Future.wait<void>(<Future<void>>[initFuture, overlappingReset]);

      // Subsequent session requests must drain normally on reconnect.
      activeSessions['new-s2'] = _buildSession(topic: 'new-s2');
      pendingRequests['905'] = const SessionRequest(
        id: 905,
        topic: 'new-s2',
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
          'new-s2',
          null,
          requestId: 905,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'address': 'z1...'});

      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      verify(
        () => nomService.handleZnnInfo(
          'new-s2',
          null,
          requestId: 905,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).called(1);
    });

    test(
      'flushes sessions.persist() and keeps reset marker pending when remote '
      'disconnectSession evicts in-memory state before persist fails',
      () async {
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{
              Web3WalletService.pendingResetStorageKey: <String, dynamic>{
                'pending': true,
                'fullReset': true,
              },
            };
        when(() => coreStorage.has(any())).thenAnswer(
          (Invocation i) =>
              persistedStorage.containsKey(i.positionalArguments[0]),
        );
        when(() => coreStorage.get(any())).thenAnswer(
          (Invocation i) => persistedStorage[i.positionalArguments[0]],
        );
        when(() => coreStorage.set(any(), any())).thenAnswer((
          Invocation i,
        ) async {
          persistedStorage[i.positionalArguments[0]
              as String] = Map<String, dynamic>.from(
            i.positionalArguments[1] as Map<String, dynamic>,
          );
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          persistedStorage.remove(i.positionalArguments[0] as String);
        });

        activeSessions['evicted-s1'] = _buildSession(topic: 'evicted-s1');
        // Simulate reown_sign removing the session in memory before persist()
        // throws inside disconnectSession.
        when(
          () => walletKit.disconnectSession(
            topic: 'evicted-s1',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) async {
          activeSessions.remove('evicted-s1');
          throw StateError('storage persist failed');
        });
        // Follow-up sessions.delete() is a no-op once absent from memory.
        when(() => sessionStore.delete('evicted-s1')).thenAnswer((_) async {});

        bool failPersist = true;
        when(sessionStore.persist).thenAnswer((_) async {
          if (failPersist) {
            throw StateError('storage persist still failing');
          }
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        verify(sessionStore.persist).called(1);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isTrue,
        );

        // Once persist recovers, retrying disconnectEverything flushes and
        // clears the marker.
        failPersist = false;
        await service.disconnectEverything();

        verify(sessionStore.persist).called(1);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'drains pending requests for surviving sessions after a partial startup '
      'reset completes',
      () async {
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{
              Web3WalletService.pendingResetStorageKey: <String, dynamic>{
                'pending': true,
                'fullReset': false,
                'pendingSessions': <Map<String, String>>[
                  <String, String>{
                    'topic': 'old-s1',
                    'publicKey': 'old-self-key',
                  },
                ],
              },
            };
        when(() => coreStorage.has(any())).thenAnswer(
          (Invocation i) =>
              persistedStorage.containsKey(i.positionalArguments[0]),
        );
        when(() => coreStorage.get(any())).thenAnswer(
          (Invocation i) => persistedStorage[i.positionalArguments[0]],
        );
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          persistedStorage.remove(i.positionalArguments[0] as String);
        });

        activeSessions['surviving-s2'] = _buildSession(topic: 'surviving-s2');
        pendingRequests['910'] = const SessionRequest(
          id: 910,
          topic: 'surviving-s2',
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
            'surviving-s2',
            null,
            requestId: 910,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).thenAnswer((_) async => <String, dynamic>{'address': 'z1...'});

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();
        await Future<void>.delayed(Duration.zero);

        verify(() => crypto.deleteKeyPair('old-self-key')).called(1);
        verify(
          () => nomService.handleZnnInfo(
            'surviving-s2',
            null,
            requestId: 910,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).called(1);
      },
    );

    test('runtime disconnectEverything persists live session and pairing '
        'targets in reset marker before sweeping', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<String> events = <String>[];
      Map<String, dynamic>? persistedPayload;
      final Completer<void> markerWriteStarted = Completer<void>();
      final Completer<void> releaseMarkerWrite = Completer<void>();
      activeSessions['live-s1'] = _buildSession(topic: 'live-s1');
      when(pairingStore.getAll).thenReturn(<PairingInfo>[
        PairingInfo(
          topic: 'live-p1',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ]);
      when(
        () => coreStorage.set(Web3WalletService.pendingResetStorageKey, any()),
      ).thenAnswer((Invocation i) async {
        events.add('persist_marker');
        persistedPayload = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
        if (!markerWriteStarted.isCompleted) {
          markerWriteStarted.complete();
        }
        await releaseMarkerWrite.future;
      });
      when(
        () => walletKit.disconnectSession(
          topic: 'live-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        events.add('disconnect_session');
        activeSessions.remove('live-s1');
      });
      when(() => pairing.disconnect(topic: 'live-p1')).thenAnswer((_) async {
        events.add('disconnect_pairing');
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      final Future<void> resetFuture = service.disconnectEverything();
      await markerWriteStarted.future;
      await Future<void>.delayed(Duration.zero);

      // Neither disconnect may start before the marker write finishes.
      expect(events, equals(<String>['persist_marker']));
      verifyNever(
        () => walletKit.disconnectSession(
          topic: 'live-s1',
          reason: any(named: 'reason'),
        ),
      );
      verifyNever(() => pairing.disconnect(topic: 'live-p1'));

      releaseMarkerWrite.complete();
      await resetFuture;

      expect(
        events,
        equals(<String>[
          'persist_marker',
          'disconnect_session',
          'disconnect_pairing',
        ]),
      );
      expect(persistedPayload?['fullReset'], isTrue);
      expect(
        persistedPayload?['pendingSessions'],
        equals(<Map<String, String>>[
          <String, String>{'topic': 'live-s1', 'publicKey': 'self-key'},
        ]),
      );
      expect(persistedPayload?['pendingPairings'], equals(<String>['live-p1']));
    });

    test('drains pending requests on surviving sessions after pair() finishes '
        'a previously failed partial reset retry', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': false,
              'pendingSessions': <Map<String, String>>[
                <String, String>{'topic': 'old-s1', 'publicKey': 'old-pk'},
              ],
            },
          };
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      bool failKeyDelete = true;
      when(() => crypto.deleteKeyPair('old-pk')).thenAnswer((_) async {
        if (failKeyDelete) {
          throw StateError('keychain locked');
        }
      });

      activeSessions['surviving-s2'] = _buildSession(topic: 'surviving-s2');
      pendingRequests['920'] = const SessionRequest(
        id: 920,
        topic: 'surviving-s2',
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
          'surviving-s2',
          null,
          requestId: 920,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{'address': 'z1...'});
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer(
        (_) async => PairingInfo(
          topic: 'new-p',
          expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      );

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();
      await Future<void>.delayed(Duration.zero);

      // Startup cleanup failed, so surviving-s2 was NOT drained yet.
      verifyNever(
        () => nomService.handleZnnInfo(
          'surviving-s2',
          null,
          requestId: 920,
          verifyContext: any(named: 'verifyContext'),
        ),
      );

      // Once keychain unlocks and pair() retries cleanup, the gate clears
      // and surviving-s2's pending request drains automatically.
      failKeyDelete = false;
      await service.pair(Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def'));
      await Future<void>.delayed(Duration.zero);

      verify(
        () => nomService.handleZnnInfo(
          'surviving-s2',
          null,
          requestId: 920,
          verifyContext: any(named: 'verifyContext'),
        ),
      ).called(1);
    });

    test('keeps pairing topic pending until keychain.persist() succeeds after '
        'a failed deleteSymKey', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'keychain-p1',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ];
      when(pairingStore.getAll).thenAnswer((_) => livePairings);
      when(() => pairingStore.delete('keychain-p1')).thenAnswer((_) async {
        livePairings.clear();
      });
      when(
        () => pairing.disconnect(topic: 'keychain-p1'),
      ).thenThrow(StateError('offline'));

      int deleteSymKeyCalls = 0;
      when(() => crypto.deleteSymKey('keychain-p1')).thenAnswer((_) async {
        deleteSymKeyCalls++;
        if (deleteSymKeyCalls == 1) {
          // Attempt 1 evicts in memory then fails persist().
          throw StateError('keychain persist failed');
        }
        // Subsequent calls return early (missing from memory).
      });
      bool failKeyChainPersist = true;
      when(keyChainStore.persist).thenAnswer((_) async {
        if (failKeyChainPersist) {
          throw StateError('keychain persist still failing');
        }
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isTrue,
      );

      // Attempt 2: deleteSymKey is a no-op, so keyChain.persist() is called
      // and still fails -> marker stays pending with keychain-p1.
      await service.disconnectEverything();
      verify(keyChainStore.persist).called(1);
      expect(
        persistedStorage[Web3WalletService
            .pendingResetStorageKey]?['pendingPairings'],
        equals(<String>['keychain-p1']),
      );

      // Attempt 3: keyChain.persist() succeeds -> marker finally clears.
      failKeyChainPersist = false;
      await service.disconnectEverything();
      verify(keyChainStore.persist).called(1);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test(
      'pre-init disconnectEverything merges existing residual targets into '
      'new full-reset marker without dropping unrecoverable public keys',
      () async {
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{
              Web3WalletService.pendingResetStorageKey: <String, dynamic>{
                'pending': true,
                'fullReset': false,
                'pendingSessions': <Map<String, String>>[
                  <String, String>{
                    'topic': 'orphan-s1',
                    'publicKey': 'orphan-pk1',
                  },
                ],
                'pendingPairings': <String>['orphan-p1'],
              },
            };
        when(() => coreStorage.has(any())).thenAnswer(
          (Invocation i) =>
              persistedStorage.containsKey(i.positionalArguments[0]),
        );
        when(() => coreStorage.get(any())).thenAnswer(
          (Invocation i) => persistedStorage[i.positionalArguments[0]],
        );
        when(() => coreStorage.set(any(), any())).thenAnswer((
          Invocation i,
        ) async {
          persistedStorage[i.positionalArguments[0]
              as String] = Map<String, dynamic>.from(
            i.positionalArguments[1] as Map<String, dynamic>,
          );
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.disconnectEverything();

        final Map<String, dynamic> updated =
            persistedStorage[Web3WalletService.pendingResetStorageKey]!;
        expect(updated['fullReset'], isTrue);
        expect(
          updated['pendingSessions'],
          equals(<Map<String, String>>[
            <String, String>{'topic': 'orphan-s1', 'publicKey': 'orphan-pk1'},
          ]),
        );
        expect(updated['pendingPairings'], equals(<String>['orphan-p1']));
      },
    );

    test('does not delete a newer pre-init full-reset marker written while an '
        'earlier startup partial reset is in flight', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': false,
              'pendingSessions': <Map<String, String>>[
                <String, String>{'topic': 'old-s1', 'publicKey': 'old-pk'},
              ],
            },
          };
      final List<String> markerOps = <String>[];
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
        markerOps.add('set:fullReset=${payload['fullReset']}');
        persistedStorage[i.positionalArguments[0] as String] = payload;
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        markerOps.add('delete');
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['live-s2'] = _buildSession(topic: 'live-s2');
      final Completer<void> partialCleanupStarted = Completer<void>();
      final Completer<void> partialCleanupGate = Completer<void>();
      when(() => crypto.deleteKeyPair('old-pk')).thenAnswer((_) {
        if (!partialCleanupStarted.isCompleted) {
          partialCleanupStarted.complete();
        }
        return partialCleanupGate.future;
      });
      when(
        () => walletKit.disconnectSession(
          topic: 'live-s2',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        markerOps.add('disconnect:live-s2');
        activeSessions.remove('live-s2');
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();

      final Future<void> initFuture = service.init();
      await partialCleanupStarted.future;

      // While the startup partial cleanup is paused on old-pk, user triggers
      // a full reset.
      await service.disconnectEverything();

      partialCleanupGate.complete();
      await initFuture;

      // The partial run must NOT have deleted the marker before the full
      // sweep ran on live-s2; delete must occur ONLY after live-s2 is wiped.
      expect(markerOps.where((String op) => op == 'delete'), hasLength(1));
      expect(
        markerOps.indexOf('disconnect:live-s2'),
        lessThan(markerOps.indexOf('delete')),
      );
      expect(activeSessions, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test('flushes keychain.persist() after failed disconnectSession even when '
        'deleteSymKey is a no-op', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['kc-s1'] = _buildSession(topic: 'kc-s1');
      when(
        () => walletKit.disconnectSession(
          topic: 'kc-s1',
          reason: any(named: 'reason'),
        ),
      ).thenThrow(StateError('keychain persist failed inside disconnect'));

      bool failKeyChainPersist = true;
      when(keyChainStore.persist).thenAnswer((_) async {
        if (failKeyChainPersist) {
          throw StateError('keychain persist still failing');
        }
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      verify(keyChainStore.persist).called(1);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isTrue,
      );

      failKeyChainPersist = false;
      await service.disconnectEverything();
      verify(keyChainStore.persist).called(1);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test('persists recovered live publicKey when stored marker entry has an '
        'empty publicKey with the same target count', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
              'pendingSessions': <Map<String, String>>[
                <String, String>{'topic': 's1', 'publicKey': ''},
              ],
            },
          };
      final List<Map<String, dynamic>> writtenMarkers =
          <Map<String, dynamic>>[];
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
        writtenMarkers.add(payload);
        persistedStorage[i.positionalArguments[0] as String] = payload;
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['s1'] = _buildSession(topic: 's1');
      when(
        () => walletKit.disconnectSession(
          topic: 's1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        activeSessions.remove('s1');
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      expect(writtenMarkers, hasLength(1));
      expect(
        writtenMarkers.single['pendingSessions'],
        equals(<Map<String, String>>[
          <String, String>{'topic': 's1', 'publicKey': 'self-key'},
        ]),
      );
    });

    test('aborts startup cleanup before deleting records if persisting reset '
        'targets fails, and completes cleanup once storage recovers', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      bool failMarkerWrite = true;
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        if (failMarkerWrite) {
          throw StateError('storage temporarily read-only');
        }
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['protected-s1'] = _buildSession(topic: 'protected-s1');
      when(
        () => walletKit.disconnectSession(
          topic: 'protected-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        activeSessions.remove('protected-s1');
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Target persistence failed -> startup must NOT have deleted protected-s1
      // and must keep the reset marker pending and pair() blocked.
      verifyNever(
        () => walletKit.disconnectSession(
          topic: 'protected-s1',
          reason: any(named: 'reason'),
        ),
      );
      verifyNever(() => sessionStore.delete('protected-s1'));
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isTrue,
      );
      await expectLater(
        service.pair(Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def')),
        throwsStateError,
      );

      // Once marker write recovers, retry persists targets, sweeps
      // protected-s1, and clears the marker.
      failMarkerWrite = false;
      await service.disconnectEverything();

      verify(
        () => walletKit.disconnectSession(
          topic: 'protected-s1',
          reason: any(named: 'reason'),
        ),
      ).called(1);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test(
      'successful pairing disconnect during full reset still purges '
      'pairing symKey and expirer and keeps marker pending on key failure',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        when(() => coreStorage.has(any())).thenAnswer(
          (Invocation i) =>
              persistedStorage.containsKey(i.positionalArguments[0]),
        );
        when(() => coreStorage.get(any())).thenAnswer(
          (Invocation i) => persistedStorage[i.positionalArguments[0]],
        );
        when(() => coreStorage.set(any(), any())).thenAnswer((
          Invocation i,
        ) async {
          persistedStorage[i.positionalArguments[0]
              as String] = Map<String, dynamic>.from(
            i.positionalArguments[1] as Map<String, dynamic>,
          );
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          persistedStorage.remove(i.positionalArguments[0] as String);
        });

        final List<PairingInfo> livePairings = <PairingInfo>[
          PairingInfo(
            topic: 'ok-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        ];
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'ok-p1')).thenAnswer((_) async {
          // Reown removes the pairing record without deleting symKey/expirer.
          livePairings.clear();
        });

        bool failSymKeyDelete = true;
        when(() => crypto.deleteSymKey('ok-p1')).thenAnswer((_) async {
          if (failSymKeyDelete) {
            throw StateError('keychain temporarily locked');
          }
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        await service.disconnectEverything();

        // Remote pairing.disconnect succeeded, yet symKey delete failed ->
        // marker must stay pending with ok-p1 instead of clearing.
        verify(() => pairing.disconnect(topic: 'ok-p1')).called(1);
        verify(() => crypto.deleteSymKey('ok-p1')).called(1);
        verify(() => expirer.delete('ok-p1')).called(1);
        expect(
          persistedStorage[Web3WalletService
              .pendingResetStorageKey]?['pendingPairings'],
          equals(<String>['ok-p1']),
        );

        // Once keychain unlocks, retry finishes symKey cleanup and clears
        // marker.
        failSymKeyDelete = false;
        await service.disconnectEverything();

        verify(() => crypto.deleteSymKey('ok-p1')).called(1);
        verify(keyChainStore.persist).called(1);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test('rewrites unconfirmed marker write before sweeping when failed '
        'storage.set already updated in-memory cache', () async {
      final Map<String, Map<String, dynamic>> cachedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': true,
            },
          };
      bool failDiskFlush = true;
      int setAttempts = 0;
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) => cachedStorage.containsKey(i.positionalArguments[0]),
      );
      when(
        () => coreStorage.get(any()),
      ).thenAnswer((Invocation i) => cachedStorage[i.positionalArguments[0]]);
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        setAttempts++;
        // Mutate the in-memory storage cache BEFORE failing the disk flush,
        // matching Reown's storage behavior.
        cachedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
        if (failDiskFlush) {
          throw StateError('disk flush failed');
        }
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        cachedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['cached-s1'] = _buildSession(topic: 'cached-s1');
      when(
        () => walletKit.disconnectSession(
          topic: 'cached-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        activeSessions.remove('cached-s1');
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer(
        (_) async => PairingInfo(
          topic: 'new-p',
          expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      );

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Startup write failed after caching targets -> must abort before sweep.
      expect(setAttempts, equals(1));
      verifyNever(
        () => walletKit.disconnectSession(
          topic: 'cached-s1',
          reason: any(named: 'reason'),
        ),
      );

      // pair() retries with forceFullReset: false. Even though cachedStorage
      // already holds cached-s1, the unconfirmed write flag must force a
      // rewrite and abort again while disk flush is still failing.
      await expectLater(
        service.pair(Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def')),
        throwsStateError,
      );
      expect(setAttempts, equals(2));
      verifyNever(
        () => walletKit.disconnectSession(
          topic: 'cached-s1',
          reason: any(named: 'reason'),
        ),
      );

      // Once disk flush recovers, pair() rewrites and confirms the marker,
      // then sweeps cached-s1, clears the marker, and completes pairing.
      failDiskFlush = false;
      final PairingInfo pairingResult = await service.pair(
        Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def'),
      );
      expect(pairingResult.topic, equals('new-p'));
      expect(setAttempts, equals(3));
      verify(
        () => walletKit.disconnectSession(
          topic: 'cached-s1',
          reason: any(named: 'reason'),
        ),
      ).called(1);
      expect(
        cachedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test('blocks session proposals and approveSession while a reset is active '
        'or unresolved', () async {
      final Completer<void> markerWriteStarted = Completer<void>();
      final Completer<void> releaseMarkerWrite = Completer<void>();
      when(
        () => coreStorage.set(Web3WalletService.pendingResetStorageKey, any()),
      ).thenAnswer((_) async {
        if (!markerWriteStarted.isCompleted) {
          markerWriteStarted.complete();
        }
        await releaseMarkerWrite.future;
      });
      when(
        () => walletKit.approveSession(
          id: any(named: 'id'),
          namespaces: any(named: 'namespaces'),
        ),
      ).thenAnswer(
        (_) async => ApproveResponse(
          topic: 'approved-s1',
          session: _buildSession(topic: 'approved-s1'),
        ),
      );

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      final Future<void> resetFuture = service.disconnectEverything();
      await markerWriteStarted.future;

      final ProposalData proposal = ProposalData(
        id: 77,
        expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
        relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
        proposer: const ConnectionMetadata(
          publicKey: 'peer-pk',
          metadata: PairingMetadata(
            name: 'dApp',
            description: 'Test',
            url: 'https://example.invalid',
          ),
        ),
        requiredNamespaces: <String, RequiredNamespace>{
          'zenon': const RequiredNamespace(
            chains: <String>['zenon:1'],
            methods: <String>['znn_info'],
            events: <String>['addressChange'],
          ),
        },
        optionalNamespaces: const <String, RequiredNamespace>{},
        pairingTopic: 'p-77',
      );

      // Incoming proposal events must be explicitly rejected (not silently
      // dropped) and direct approveSession calls must throw while the reset
      // marker write is pending.
      onSessionProposal.broadcast(SessionProposalEvent(77, proposal));
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        service.approveSession(
          id: 77,
          namespaces: service.buildApprovedNamespaces(proposal),
          pairingTopic: proposal.pairingTopic,
        ),
        throwsStateError,
      );
      verifyNever(
        () => walletKit.approveSession(
          id: any(named: 'id'),
          namespaces: any(named: 'namespaces'),
        ),
      );
      final VerificationResult rejected = verify(
        () => walletKit.rejectSession(
          id: 77,
          reason: captureAny(named: 'reason'),
        ),
      )..called(1);
      expect(
        (rejected.captured.single as ReownSignError).code,
        equals(Errors.getSdkError(Errors.USER_REJECTED).code),
      );

      releaseMarkerWrite.complete();
      await resetFuture;
    });

    test('commits a post-snapshot live session to the reset marker before '
        'deleting it during a full reset', () async {
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{};
      final List<String> events = <String>[];
      final List<Map<String, dynamic>> writtenMarkers =
          <Map<String, dynamic>>[];
      final Completer<void> firstWriteStarted = Completer<void>();
      final Completer<void> releaseFirstWrite = Completer<void>();

      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
        writtenMarkers.add(payload);
        persistedStorage[i.positionalArguments[0] as String] = payload;
        final List<dynamic> sessionsList =
            (payload['pendingSessions'] as List<dynamic>?) ?? const <dynamic>[];
        final List<String> topics = sessionsList
            .map((dynamic e) => (e as Map<dynamic, dynamic>)['topic'] as String)
            .toList();
        events.add('persist:${topics.join(',')}');
        if (!firstWriteStarted.isCompleted) {
          firstWriteStarted.complete();
          await releaseFirstWrite.future;
        }
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        events.add('clear_marker');
        persistedStorage.remove(i.positionalArguments[0] as String);
      });

      activeSessions['live-s1'] = _buildSession(
        topic: 'live-s1',
        selfPublicKey: 'pk-1',
      );
      when(
        () => walletKit.disconnectSession(
          topic: any(named: 'topic'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((Invocation i) async {
        final String topic = i.namedArguments[#topic] as String;
        events.add('disconnect:$topic');
        activeSessions.remove(topic);
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      final Future<void> resetFuture = service.disconnectEverything();
      await firstWriteStarted.future;

      // Simulate an already-in-flight approveSession completing while the
      // initial reset marker write is pending.
      activeSessions['late-s2'] = _buildSession(
        topic: 'late-s2',
        selfPublicKey: 'pk-2',
      );
      releaseFirstWrite.complete();
      await resetFuture;

      // Pass 1 must only delete live-s1 (the committed target). Pass 2 must
      // persist late-s2's (topic, publicKey) BEFORE deleting late-s2.
      expect(
        events,
        equals(<String>[
          'persist:live-s1',
          'disconnect:live-s1',
          'persist:late-s2',
          'disconnect:late-s2',
          'clear_marker',
        ]),
      );
      expect(
        writtenMarkers[1]['pendingSessions'],
        equals(<Map<String, String>>[
          <String, String>{'topic': 'late-s2', 'publicKey': 'pk-2'},
        ]),
      );
      expect(activeSessions, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test('blocks pair() paused in _cleanupStalePairings() when a full reset '
        'starts and pauses inside core.storage.delete', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{};
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'orphan-p1',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      ];
      final Completer<void> orphanCleanupStarted = Completer<void>();
      final Completer<void> releaseOrphanCleanup = Completer<void>();
      final Completer<void> markerDeleteStarted = Completer<void>();
      final Completer<void> releaseMarkerDelete = Completer<void>();

      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        if (!markerDeleteStarted.isCompleted) {
          markerDeleteStarted.complete();
        }
        await releaseMarkerDelete.future;
        persistedStorage.remove(i.positionalArguments[0] as String);
      });
      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'orphan-p1')).thenAnswer((_) async {
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-p1');
        if (!orphanCleanupStarted.isCompleted) {
          orphanCleanupStarted.complete();
          await releaseOrphanCleanup.future;
        }
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((_) async {
        final PairingInfo created = PairingInfo(
          topic: 'leaked-p2',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings.add(created);
        return created;
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Start pair() and pause it inside _cleanupStalePairings().
      final Future<PairingInfo> pairFuture = service.pair(
        Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def'),
      );
      await orphanCleanupStarted.future;

      // Start full reset and pause it inside core.storage.delete.
      final Future<void> resetFuture = service.disconnectEverything();
      await markerDeleteStarted.future;

      // Resume pair(); it must fail rather than writing a pairing after the
      // reset's final scan.
      releaseOrphanCleanup.complete();
      await expectLater(pairFuture, throwsStateError);

      // Let the reset finish clearing the marker.
      releaseMarkerDelete.complete();
      await resetFuture;

      verifyNever(() => walletKit.pair(uri: any(named: 'uri')));
      expect(livePairings, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test(
      'waits for an already-in-flight SDK pair() call, commits its pairing '
      'to the reset marker, and sweeps it before clearing the marker',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final List<String> events = <String>[];
        final Completer<void> sdkPairStarted = Completer<void>();
        final Completer<void> releaseSdkPair = Completer<void>();

        when(() => coreStorage.has(any())).thenAnswer(
          (Invocation i) =>
              persistedStorage.containsKey(i.positionalArguments[0]),
        );
        when(() => coreStorage.get(any())).thenAnswer(
          (Invocation i) => persistedStorage[i.positionalArguments[0]],
        );
        when(() => coreStorage.set(any(), any())).thenAnswer((
          Invocation i,
        ) async {
          final Map<String, dynamic> payload = Map<String, dynamic>.from(
            i.positionalArguments[1] as Map<String, dynamic>,
          );
          persistedStorage[i.positionalArguments[0] as String] = payload;
          final List<dynamic> pairingsList =
              (payload['pendingPairings'] as List<dynamic>?) ??
              const <dynamic>[];
          events.add('persist:${pairingsList.join(',')}');
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          events.add('clear_marker');
          persistedStorage.remove(i.positionalArguments[0] as String);
        });
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: any(named: 'topic'))).thenAnswer((
          Invocation i,
        ) async {
          final String topic = i.namedArguments[#topic] as String;
          events.add('disconnect:$topic');
          livePairings.removeWhere((PairingInfo p) => p.topic == topic);
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          _,
        ) async {
          if (!sdkPairStarted.isCompleted) {
            sdkPairStarted.complete();
          }
          await releaseSdkPair.future;
          final PairingInfo created = PairingInfo(
            topic: 'in-flight-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings.add(created);
          events.add('sdk_pair_saved:in-flight-p1');
          return created;
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        final Future<PairingInfo> pairFuture = service.pair(
          Uri.parse('wc:abc@2?relay-protocol=irn&symKey=def'),
        );
        await sdkPairStarted.future;

        final Future<void> resetFuture = service.disconnectEverything();
        await Future<void>.delayed(Duration.zero);

        // Reset must NOT clear the marker while the admitted SDK pair() call is
        // still in flight.
        expect(events, isNot(contains('clear_marker')));

        releaseSdkPair.complete();
        await expectLater(pairFuture, throwsStateError);
        await resetFuture;

        // The pairing written by the in-flight pair() must be persisted in the
        // reset marker BEFORE being disconnected, and only then is the marker
        // cleared.
        expect(
          events,
          equals(<String>[
            'persist:',
            'sdk_pair_saved:in-flight-p1',
            'persist:in-flight-p1',
            'disconnect:in-flight-p1',
            'clear_marker',
          ]),
        );
        expect(livePairings, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test('partial reset rejects proposals for affected pairings but does not '
        'block proposals on unaffected pairings', () async {
      final _MockNotificationsBloc mockNotifications = _MockNotificationsBloc();
      when(
        () => mockNotifications.addNotification(any()),
      ).thenAnswer((_) async {});
      sl.registerSingleton<NotificationsBloc>(mockNotifications);
      addTearDown(() async {
        if (sl.isRegistered<NotificationsBloc>()) {
          await sl.unregister<NotificationsBloc>();
        }
      });

      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': false,
              'pendingPairings': <String>['old-p1'],
            },
          };
      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) =>
            persistedStorage.containsKey(i.positionalArguments[0]),
      );
      when(() => coreStorage.get(any())).thenAnswer(
        (Invocation i) => persistedStorage[i.positionalArguments[0]],
      );
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        persistedStorage[i.positionalArguments[0]
            as String] = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
      });
      when(
        () => crypto.deleteSymKey('old-p1'),
      ).thenThrow(StateError('keychain temporarily locked'));

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      final int expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300;
      const ConnectionMetadata proposer = ConnectionMetadata(
        publicKey: 'peer-pk',
        metadata: PairingMetadata(
          name: 'dApp',
          description: 'Test',
          url: 'https://example.invalid',
        ),
      );

      // Affected pairing 'old-p1' -> rejected immediately by reset guard with
      // USER_REJECTED before namespace validation.
      final ProposalData affectedProposal = ProposalData(
        id: 81,
        expiry: expiry,
        relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
        proposer: proposer,
        requiredNamespaces: <String, RequiredNamespace>{
          'eip155': const RequiredNamespace(
            chains: <String>['eip155:1'],
            methods: <String>['eth_sendTransaction'],
            events: <String>[],
          ),
        },
        optionalNamespaces: const <String, RequiredNamespace>{},
        pairingTopic: 'old-p1',
      );
      onSessionProposal.broadcast(SessionProposalEvent(81, affectedProposal));
      await Future<void>.delayed(Duration.zero);

      final VerificationResult affectedReject = verify(
        () => walletKit.rejectSession(
          id: 81,
          reason: captureAny(named: 'reason'),
        ),
      )..called(1);
      expect(
        (affectedReject.captured.single as ReownSignError).code,
        equals(Errors.getSdkError(Errors.USER_REJECTED).code),
      );

      // Unaffected pairing 'surviving-p2' -> passes the reset guard and enters
      // normal proposal processing (e.g. rejects with UNSUPPORTED_NAMESPACE_KEY
      // instead of being dropped or reset-rejected).
      final ProposalData unaffectedProposal = ProposalData(
        id: 82,
        expiry: expiry,
        relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
        proposer: proposer,
        requiredNamespaces: <String, RequiredNamespace>{
          'eip155': const RequiredNamespace(
            chains: <String>['eip155:1'],
            methods: <String>['eth_sendTransaction'],
            events: <String>[],
          ),
        },
        optionalNamespaces: const <String, RequiredNamespace>{},
        pairingTopic: 'surviving-p2',
      );
      onSessionProposal.broadcast(SessionProposalEvent(82, unaffectedProposal));
      await Future<void>.delayed(Duration.zero);

      final VerificationResult unaffectedReject = verify(
        () => walletKit.rejectSession(
          id: 82,
          reason: captureAny(named: 'reason'),
        ),
      )..called(1);
      expect(
        (unaffectedReject.captured.single as ReownSignError).code,
        equals(Errors.getSdkError(Errors.UNSUPPORTED_NAMESPACE_KEY).code),
      );
    });

    test('finalizeApprovedSession skips reporting a reset-deleted session and '
        'uses the live stored session when still present', () async {
      final _MockNotificationsBloc mockNotifications = _MockNotificationsBloc();
      when(
        () => mockNotifications.addNotification(any()),
      ).thenAnswer((_) async {});
      sl.registerSingleton<NotificationsBloc>(mockNotifications);
      addTearDown(() async {
        if (sl.isRegistered<NotificationsBloc>()) {
          await sl.unregister<NotificationsBloc>();
        }
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      const PairingMetadata dAppMetadata = PairingMetadata(
        name: 'Test dApp',
        description: 'dApp',
        url: 'https://example.invalid',
      );

      // Case 1: Session was deleted from SDK store by a concurrent reset
      // before approveSession returned its saved SessionData.
      final bool finalizedDeleted = await service.finalizeApprovedSession(
        proposalId: 91,
        approveResponse: ApproveResponse(
          topic: 'reset-deleted-s1',
          session: _buildSession(topic: 'reset-deleted-s1'),
        ),
        dAppMetadata: dAppMetadata,
      );
      expect(finalizedDeleted, isFalse);
      expect(service.sessions.value, isEmpty);
      verifyNever(() => mockNotifications.addNotification(any()));

      // Case 2: Session remains in the SDK store -> uses the live stored
      // record and notifies success.
      activeSessions['live-s2'] = _buildSession(
        topic: 'live-s2',
        selfPublicKey: 'live-store-pk',
      );
      final bool finalizedLive = await service.finalizeApprovedSession(
        proposalId: 92,
        approveResponse: ApproveResponse(
          topic: 'live-s2',
          session: _buildSession(
            topic: 'live-s2',
            selfPublicKey: 'stale-response-pk',
          ),
        ),
        dAppMetadata: dAppMetadata,
      );
      expect(finalizedLive, isTrue);
      expect(service.sessions.value, hasLength(1));
      expect(
        service.sessions.value.single.self.publicKey,
        equals('live-store-pk'),
      );
      verify(() => mockNotifications.addNotification(any())).called(1);
    });
  });
}
