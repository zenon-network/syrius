import 'dart:async';

import 'package:flutter/services.dart';
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
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/wallet_connect_metadata_utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/nom_service.dart';
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
      when(() => relayClient.disconnect()).thenAnswer((_) async {});
      when(() => relayClient.connect()).thenAnswer((_) async {});
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

    test('stops stale-pairing cleanup when reset completes and a new pair() '
        'recreates the next orphan topic', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{};
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'orphan-a',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
        PairingInfo(
          topic: 'orphan-b',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      ];
      final Completer<void> orphanADisconnectStarted = Completer<void>();
      final Completer<void> releaseOrphanADisconnect = Completer<void>();
      int orphanBDisconnects = 0;

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
      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'orphan-a')).thenAnswer((_) async {
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-a');
        if (!orphanADisconnectStarted.isCompleted) {
          orphanADisconnectStarted.complete();
          await releaseOrphanADisconnect.future;
        }
      });
      when(() => pairing.disconnect(topic: 'orphan-b')).thenAnswer((_) async {
        orphanBDisconnects++;
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-b');
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((_) async {
        final PairingInfo recreated = PairingInfo(
          topic: 'orphan-b',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings.add(recreated);
        return recreated;
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Old pair() pauses while disconnecting orphan-a (with orphan-b next in
      // its snapshot of stale pairings).
      final Future<PairingInfo> stalePairFuture = service.pair(
        Uri.parse('wc:old@2?relay-protocol=irn&symKey=def'),
      );
      await orphanADisconnectStarted.future;

      // Full reset completes and wipes the old orphan-b (disconnect count = 1).
      await service.disconnectEverything();
      expect(orphanBDisconnects, equals(1));
      expect(livePairings, isEmpty);

      // New post-reset pair() saves a fresh pairing with topic orphan-b.
      final PairingInfo freshPairing = await service.pair(
        Uri.parse('wc:orphan-b@2?relay-protocol=irn&symKey=ghi'),
      );
      expect(freshPairing.topic, equals('orphan-b'));
      expect(livePairings.map((PairingInfo p) => p.topic), <String>[
        'orphan-b',
      ]);

      // Resume old pair(): stale cleanup must stop before disconnecting the
      // recreated orphan-b, and the old pair() call must fail with StateError.
      releaseOrphanADisconnect.complete();
      await expectLater(stalePairFuture, throwsStateError);

      expect(orphanBDisconnects, equals(1));
      expect(livePairings.map((PairingInfo p) => p.topic), <String>[
        'orphan-b',
      ]);
    });

    test(
      'waits for an admitted SDK pair() call before purging its visible '
      'pairing record so delayed symKey and expirer writes are purged',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final Set<String> storedSymKeys = <String>{};
        final Set<String> storedExpirers = <String>{};
        final Completer<void> recordVisible = Completer<void>();
        final Completer<void> releaseDelayedWrites = Completer<void>();

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'partial-p1')).thenAnswer((
          _,
        ) async {
          livePairings.removeWhere((PairingInfo p) => p.topic == 'partial-p1');
        });
        when(() => crypto.deleteSymKey('partial-p1')).thenAnswer((_) async {
          storedSymKeys.remove('partial-p1');
        });
        when(() => expirer.delete('partial-p1')).thenAnswer((_) async {
          storedExpirers.remove('partial-p1');
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          _,
        ) async {
          // Reown writes the pairing record BEFORE symKey and expirer.
          final PairingInfo created = PairingInfo(
            topic: 'partial-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings.add(created);
          if (!recordVisible.isCompleted) {
            recordVisible.complete();
          }
          await releaseDelayedWrites.future;
          storedSymKeys.add('partial-p1');
          storedExpirers.add('partial-p1');
          return created;
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        final Future<PairingInfo> pairFuture = service.pair(
          Uri.parse('wc:partial-p1@2?relay-protocol=irn&symKey=def'),
        );
        await recordVisible.future;

        // Start full reset while the record is visible but symKey/expirer have
        // not been written yet.
        final Future<void> resetFuture = service.disconnectEverything();
        await Future<void>.delayed(Duration.zero);

        // Reset must persist the marker with partial-p1 and wait for pair() to
        // settle BEFORE purging partial-p1 or clearing the marker.
        expect(
          persistedStorage[Web3WalletService
              .pendingResetStorageKey]?['pendingPairings'],
          equals(<String>['partial-p1']),
        );
        verifyNever(() => pairing.disconnect(topic: 'partial-p1'));
        verifyNever(() => crypto.deleteSymKey('partial-p1'));

        // Release pair()'s delayed symKey + expirer writes.
        releaseDelayedWrites.complete();
        await expectLater(pairFuture, throwsStateError);
        await resetFuture;

        expect(livePairings, isEmpty);
        expect(storedSymKeys, isEmpty);
        expect(storedExpirers, isEmpty);
        verify(() => crypto.deleteSymKey('partial-p1')).called(1);
        verify(() => expirer.delete('partial-p1')).called(1);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'bounds wait for a hung admitted SDK pair() call, propagates '
      'TimeoutException, and keeps the full-reset marker pending until retry',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final Set<String> storedSymKeys = <String>{};
        final Completer<void> sdkPairStarted = Completer<void>();
        final Completer<void> releaseHungPair = Completer<void>();

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'hung-p1')).thenAnswer((_) async {
          livePairings.removeWhere((PairingInfo p) => p.topic == 'hung-p1');
        });
        when(() => crypto.deleteSymKey('hung-p1')).thenAnswer((_) async {
          storedSymKeys.remove('hung-p1');
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          _,
        ) async {
          if (!sdkPairStarted.isCompleted) {
            sdkPairStarted.complete();
          }
          await releaseHungPair.future;
          final PairingInfo created = PairingInfo(
            topic: 'hung-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings.add(created);
          storedSymKeys.add('hung-p1');
          return created;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!releaseHungPair.isCompleted) {
            releaseHungPair.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Future<PairingInfo> hungPairFuture = service.pair(
          Uri.parse('wc:hung-p1@2?relay-protocol=irn&symKey=def'),
        );
        await sdkPairStarted.future;

        // Full reset must time out rather than hanging forever, propagate
        // TimeoutException to the caller, and keep the full-reset marker on
        // disk.
        await expectLater(
          service.disconnectEverything(),
          throwsA(isA<TimeoutException>()),
        );
        expect(
          persistedStorage[Web3WalletService
              .pendingResetStorageKey]?['fullReset'],
          isTrue,
        );

        // New pairings must remain blocked while the timed-out reset is
        // pending.
        await expectLater(
          service.pair(Uri.parse('wc:other@2?relay-protocol=irn&symKey=xyz')),
          throwsStateError,
        );

        // Once the hung pair() settles later and writes hung-p1, a retry sweeps
        // it (including its symKey) and clears the reset marker.
        releaseHungPair.complete();
        await expectLater(hungPairFuture, throwsStateError);

        await service.disconnectEverything();

        expect(livePairings, isEmpty);
        expect(storedSymKeys, isEmpty);
        verify(() => crypto.deleteSymKey('hung-p1')).called(1);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'bounds hung relayClient.unsubscribe during pairing purge so full reset '
      'completes and clears the reset marker',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[
          PairingInfo(
            topic: 'unsub-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        ];
        final Completer<void> neverCompletingUnsubscribe = Completer<void>();

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'unsub-p1')).thenAnswer((_) async {
          livePairings.clear();
        });
        when(
          () => relayClient.unsubscribe(topic: 'unsub-p1'),
        ).thenAnswer((_) => neverCompletingUnsubscribe.future);

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!neverCompletingUnsubscribe.isCompleted) {
            neverCompletingUnsubscribe.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        await service.disconnectEverything().timeout(
          const Duration(seconds: 2),
        );

        verify(() => pairing.disconnect(topic: 'unsub-p1')).called(1);
        verify(() => crypto.deleteSymKey('unsub-p1')).called(1);
        verify(() => expirer.delete('unsub-p1')).called(1);
        expect(livePairings, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'reset retry disconnects the relay to terminate a hung SDK pair() call, '
      'confirms settlement, sweeps local state, and clears the marker',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final Set<String> storedSymKeys = <String>{};
        final Completer<void> sdkPairStarted = Completer<void>();
        final Completer<void> relaySubscribeResponse = Completer<void>();

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'stuck-p1')).thenAnswer((_) async {
          // Relay is disconnected during retry recovery, so remote disconnect
          // throws and local purge cleans up the record + symKey + expirer.
          throw StateError('relay disconnected');
        });
        when(() => pairingStore.delete('stuck-p1')).thenAnswer((_) async {
          livePairings.removeWhere((PairingInfo p) => p.topic == 'stuck-p1');
        });
        when(() => crypto.deleteSymKey('stuck-p1')).thenAnswer((_) async {
          storedSymKeys.remove('stuck-p1');
        });
        when(() => relayClient.disconnect()).thenAnswer((_) async {
          // Mirrors Reown RelayClient._disconnect() closing jsonRPC, which
          // immediately fails the unanswered relay subscribe request.
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.completeError(
              StateError('relay socket closed'),
            );
          }
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          _,
        ) async {
          // Reown writes pairing record and symKey before awaiting relay
          // subscribe.
          final PairingInfo created = PairingInfo(
            topic: 'stuck-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings.add(created);
          storedSymKeys.add('stuck-p1');
          if (!sdkPairStarted.isCompleted) {
            sdkPairStarted.complete();
          }
          await relaySubscribeResponse.future;
          return created;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Future<PairingInfo> hungPairFuture = service.pair(
          Uri.parse('wc:stuck-p1@2?relay-protocol=irn&symKey=def'),
        );
        final Future<void> hungPairExpectation = expectLater(
          hungPairFuture,
          throwsStateError,
        );
        await sdkPairStarted.future;

        // First attempt times out without disconnecting the relay, keeping the
        // durable full-reset marker on disk so the splash flow can retry.
        await expectLater(
          service.disconnectEverything(),
          throwsA(isA<TimeoutException>()),
        );
        verifyNever(() => relayClient.disconnect());
        expect(
          persistedStorage[Web3WalletService
              .pendingResetStorageKey]?['fullReset'],
          isTrue,
        );

        // Retry recovers WITHOUT external intervention by disconnecting the
        // relay to terminate the hung subscribe call, confirming settlement,
        // purging local state + symKey, clearing the marker, and reconnecting.
        await service.disconnectEverything();
        await hungPairExpectation;
        await Future<void>.delayed(Duration.zero);

        verify(() => relayClient.disconnect()).called(1);
        verify(() => relayClient.connect()).called(1);
        verify(() => crypto.deleteSymKey('stuck-p1')).called(1);
        verify(() => expirer.delete('stuck-p1')).called(1);
        expect(livePairings, isEmpty);
        expect(storedSymKeys, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'bounds hung live disconnectSession so local purge runs, later sessions '
      'still sweep, and late completion does not corrupt state',
      () async {
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Completer<void> hungDisconnectCompleter = Completer<void>();

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

        activeSessions['hung-s1'] = _buildSession(
          topic: 'hung-s1',
          selfPublicKey: 'pk-hung-1',
        );
        activeSessions['ok-s2'] = _buildSession(
          topic: 'ok-s2',
          selfPublicKey: 'pk-ok-2',
        );
        when(
          () => walletKit.disconnectSession(
            topic: 'hung-s1',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) => hungDisconnectCompleter.future);
        when(() => sessionStore.delete('hung-s1')).thenAnswer((_) async {
          activeSessions.remove('hung-s1');
        });
        when(
          () => walletKit.disconnectSession(
            topic: 'ok-s2',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) async {
          activeSessions.remove('ok-s2');
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!hungDisconnectCompleter.isCompleted) {
            hungDisconnectCompleter.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        await service.disconnectEverything().timeout(
          const Duration(seconds: 2),
        );

        verify(() => sessionStore.delete('hung-s1')).called(1);
        verify(() => crypto.deleteKeyPair('pk-hung-1')).called(1);
        verify(() => crypto.deleteSymKey('hung-s1')).called(1);
        verify(() => expirer.delete('hung-s1')).called(1);
        verify(
          () => walletKit.disconnectSession(
            topic: 'ok-s2',
            reason: any(named: 'reason'),
          ),
        ).called(1);
        // Should not wait a second timeout on a duplicate unsubscribe for the
        // already timed-out disconnectSession topic.
        verifyNever(() => relayClient.unsubscribe(topic: 'hung-s1'));
        expect(activeSessions, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );

        // Late completion/error of the timed-out disconnectSession must not
        // throw unhandled errors or disturb newer sessions, and onSessionDelete
        // must still refresh sessions.value from the live SDK store.
        activeSessions['fresh-s3'] = _buildSession(topic: 'fresh-s3');
        onSessionDelete.broadcast(SessionDelete('hung-s1'));
        hungDisconnectCompleter.completeError(StateError('late relay timeout'));
        await Future<void>.delayed(Duration.zero);

        expect(
          service.sessions.value.map((SessionData s) => s.topic),
          equals(<String>['fresh-s3']),
        );
      },
    );

    test(
      'defers topic readmission in pair() while a timed-out relay unsubscribe '
      'is still pending and allows reuse once it settles',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[
          PairingInfo(
            topic: 'reused-p1',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        ];
        final Completer<void> pendingUnsubscribe = Completer<void>();

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'reused-p1')).thenAnswer((
          _,
        ) async {
          livePairings.clear();
        });
        when(
          () => relayClient.unsubscribe(topic: 'reused-p1'),
        ).thenAnswer((_) => pendingUnsubscribe.future);
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          final PairingInfo created = PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings.add(created);
          return created;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!pendingUnsubscribe.isCompleted) {
            pendingUnsubscribe.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        // Reset finishes within the timeout bound even while unsubscribe hangs.
        await service.disconnectEverything().timeout(
          const Duration(seconds: 2),
        );

        // Reusing the same topic must be blocked until unsubscribe settles.
        await expectLater(
          service.pair(
            Uri.parse('wc:reused-p1@2?relay-protocol=irn&symKey=def'),
          ),
          throwsStateError,
        );

        // A different topic is unaffected and allowed immediately.
        final PairingInfo other = await service.pair(
          Uri.parse('wc:other-p2@2?relay-protocol=irn&symKey=ghi'),
        );
        expect(other.topic, equals('other-p2'));

        // Once the timed-out unsubscribe settles, reusing reused-p1 succeeds.
        pendingUnsubscribe.complete();
        await Future<void>.delayed(Duration.zero);

        final PairingInfo reused = await service.pair(
          Uri.parse('wc:reused-p1@2?relay-protocol=irn&symKey=def'),
        );
        expect(reused.topic, equals('reused-p1'));
      },
    );

    test('waits for a timed-out recovery relay disconnect to settle before '
        'reconnecting after reset', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{};
      final List<PairingInfo> livePairings = <PairingInfo>[];
      final Completer<void> sdkPairStarted = Completer<void>();
      final Completer<void> relaySubscribeResponse = Completer<void>();
      final Completer<void> relayDisconnectCompleter = Completer<void>();

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
      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'slow-close-p1')).thenAnswer((
        _,
      ) async {
        livePairings.clear();
      });
      when(() => relayClient.disconnect()).thenAnswer((_) {
        // Rejects the stuck subscribe request immediately while the socket
        // close future itself takes longer than the timeout to settle.
        if (!relaySubscribeResponse.isCompleted) {
          relaySubscribeResponse.completeError(
            StateError('relay socket closing'),
          );
        }
        return relayDisconnectCompleter.future;
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((_) async {
        final PairingInfo created = PairingInfo(
          topic: 'slow-close-p1',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings.add(created);
        if (!sdkPairStarted.isCompleted) {
          sdkPairStarted.complete();
        }
        await relaySubscribeResponse.future;
        return created;
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(() async {
        if (!relaySubscribeResponse.isCompleted) {
          relaySubscribeResponse.complete();
        }
        if (!relayDisconnectCompleter.isCompleted) {
          relayDisconnectCompleter.complete();
        }
        await service.onDispose();
      });
      service.create();
      await service.init();

      final Future<PairingInfo> hungPairFuture = service.pair(
        Uri.parse('wc:slow-close-p1@2?relay-protocol=irn&symKey=def'),
      );
      final Future<void> hungPairExpectation = expectLater(
        hungPairFuture,
        throwsStateError,
      );
      await sdkPairStarted.future;

      await expectLater(
        service.disconnectEverything(),
        throwsA(isA<TimeoutException>()),
      );

      // Retry times out awaiting relayClient.disconnect() (50ms), sees pair()
      // already settled, completes the sweep and clears the marker, yet must
      // NOT call relayClient.connect() while disconnect() is still pending.
      await service.disconnectEverything();
      await hungPairExpectation;
      await Future<void>.delayed(Duration.zero);

      verify(() => relayClient.disconnect()).called(1);
      verifyNever(() => relayClient.connect());

      // Once the slow disconnect future finally settles, reconnect runs.
      relayDisconnectCompleter.complete();
      await Future<void>.delayed(Duration.zero);

      verify(() => relayClient.connect()).called(1);
    });

    test('retries unconfirmed reset-marker delete after cache eviction before '
        'throw until delete succeeds', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> cachedStorage =
          <String, Map<String, dynamic>>{};
      final Map<String, Map<String, dynamic>> diskStorage =
          <String, Map<String, dynamic>>{};
      int remainingDeleteFailures = 2;
      int deleteAttempts = 0;

      when(() => coreStorage.has(any())).thenAnswer(
        (Invocation i) => cachedStorage.containsKey(i.positionalArguments[0]),
      );
      when(
        () => coreStorage.get(any()),
      ).thenAnswer((Invocation i) => cachedStorage[i.positionalArguments[0]]);
      when(() => coreStorage.set(any(), any())).thenAnswer((
        Invocation i,
      ) async {
        final String key = i.positionalArguments[0] as String;
        final Map<String, dynamic> copy = Map<String, dynamic>.from(
          i.positionalArguments[1] as Map<String, dynamic>,
        );
        cachedStorage[key] = copy;
        diskStorage[key] = Map<String, dynamic>.from(copy);
      });
      when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
        final String key = i.positionalArguments[0] as String;
        deleteAttempts++;
        // Simulate SharedPrefsStore.delete evicting from in-memory _map
        // before prefs.remove flushes to disk.
        cachedStorage.remove(key);
        if (remainingDeleteFailures > 0) {
          remainingDeleteFailures--;
          throw StateError('prefs.remove failed after cache eviction');
        }
        diskStorage.remove(key);
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer(
        (_) async => PairingInfo(
          topic: 'after-clear-p1',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      );

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // First reset writes marker, sweeps, then fails during marker delete
      // AFTER evicting the key from the in-memory cache.
      await service.disconnectEverything();
      expect(deleteAttempts, equals(1));
      expect(
        cachedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
      expect(
        diskStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isTrue,
      );

      // First pair() retry must still invoke delete() unconditionally even
      // though coreStorage.has() returns false, and keep blocking when
      // delete() throws again.
      await expectLater(
        service.pair(
          Uri.parse('wc:after-clear-p1@2?relay-protocol=irn&symKey=def'),
        ),
        throwsStateError,
      );
      expect(deleteAttempts, equals(2));
      expect(
        diskStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isTrue,
      );
      verifyNever(() => walletKit.pair(uri: any(named: 'uri')));

      // Second pair() retry succeeds once delete() flushes to disk.
      final PairingInfo created = await service.pair(
        Uri.parse('wc:after-clear-p1@2?relay-protocol=irn&symKey=def'),
      );
      expect(created.topic, equals('after-clear-p1'));
      expect(deleteAttempts, equals(3));
      expect(
        diskStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test(
      'waits for an admitted approveSession() call during full reset, aborts '
      'approval, and sweeps the newly written session',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        const MethodChannel windowManagerChannel = MethodChannel(
          'window_manager',
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(windowManagerChannel, (
              MethodCall call,
            ) async {
              if (call.method == 'isFocused' || call.method == 'isVisible') {
                return true;
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(windowManagerChannel, null);
        });

        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Completer<void> sdkApproveStarted = Completer<void>();
        final Completer<void> releaseSdkApprove = Completer<void>();
        final List<String> events = <String>[];

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
          final List<dynamic> sessionsList =
              (payload['pendingSessions'] as List<dynamic>?) ??
              const <dynamic>[];
          final List<String> topics = sessionsList
              .map(
                (dynamic e) => (e as Map<dynamic, dynamic>)['topic'] as String,
              )
              .toList();
          events.add('persist:${topics.join(',')}');
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          events.add('clear_marker');
          persistedStorage.remove(i.positionalArguments[0] as String);
        });
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
        when(
          () => walletKit.approveSession(
            id: any(named: 'id'),
            namespaces: any(named: 'namespaces'),
          ),
        ).thenAnswer((_) async {
          if (!sdkApproveStarted.isCompleted) {
            sdkApproveStarted.complete();
          }
          await releaseSdkApprove.future;
          final SessionData created = _buildSession(
            topic: 'in-flight-s1',
            selfPublicKey: 'pk-in-flight-1',
          );
          activeSessions['in-flight-s1'] = created;
          events.add('sdk_approve_saved:in-flight-s1');
          return ApproveResponse(topic: 'in-flight-s1', session: created);
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        final Future<ApproveResponse> approveFuture = service.approveSession(
          id: 501,
          namespaces: const <String, Namespace>{},
          pairingTopic: 'p-501',
        );
        await sdkApproveStarted.future;

        final Future<void> resetFuture = service.disconnectEverything();
        await Future<void>.delayed(Duration.zero);

        expect(events, isNot(contains('clear_marker')));

        releaseSdkApprove.complete();
        await expectLater(approveFuture, throwsStateError);
        await resetFuture;

        expect(
          events,
          equals(<String>[
            'persist:',
            'sdk_approve_saved:in-flight-s1',
            'persist:in-flight-s1',
            'disconnect:in-flight-s1',
            'clear_marker',
          ]),
        );
        expect(activeSessions, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test('finalizeApprovedSession rejects a pre-reset approval when '
        'resetGeneration has advanced', () async {
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

      final int preResetGeneration = service.resetGeneration;
      await service.disconnectEverything();

      // Simulate a late session write that landed after reset finished.
      final SessionData lateSession = _buildSession(topic: 'late-s1');
      activeSessions['late-s1'] = lateSession;

      final bool finalized = await service.finalizeApprovedSession(
        proposalId: 601,
        approveResponse: ApproveResponse(
          topic: 'late-s1',
          session: lateSession,
        ),
        dAppMetadata: const PairingMetadata(
          name: 'Test dApp',
          description: 'dApp',
          url: 'https://example.invalid',
        ),
        expectedResetGeneration: preResetGeneration,
      );

      expect(finalized, isFalse);
      expect(service.sessions.value, isEmpty);
      verifyNever(() => mockNotifications.addNotification(any()));
    });

    test('queued disconnectEverything() behind a running partial reset '
        'immediately gates proposals and preserves the reset marker', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{
            Web3WalletService.pendingResetStorageKey: <String, dynamic>{
              'pending': true,
              'fullReset': false,
              'pendingPairings': <String>['old-p1'],
            },
          };
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'other-p2',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ];
      activeSessions['live-s1'] = _buildSession(topic: 'live-s1');

      final Completer<void> partialCleanupStarted = Completer<void>();
      final Completer<void> releasePartialCleanup = Completer<void>();
      bool failInitialPartialCleanup = true;
      int deleteCallsBeforeFullSweep = 0;
      bool fullSweepStarted = false;

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
        if (!fullSweepStarted) {
          deleteCallsBeforeFullSweep++;
        }
        persistedStorage.remove(i.positionalArguments[0] as String);
      });
      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: any(named: 'topic'))).thenAnswer((
        Invocation i,
      ) async {
        final String topic = i.namedArguments[#topic] as String;
        if (topic == 'other-p2') {
          fullSweepStarted = true;
        }
        livePairings.removeWhere((PairingInfo p) => p.topic == topic);
      });
      when(
        () => walletKit.disconnectSession(
          topic: 'live-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        fullSweepStarted = true;
        activeSessions.remove('live-s1');
      });
      when(() => crypto.deleteSymKey('old-p1')).thenAnswer((_) async {
        if (failInitialPartialCleanup) {
          failInitialPartialCleanup = false;
          throw StateError('transient keychain lock');
        }
        if (!partialCleanupStarted.isCompleted) {
          partialCleanupStarted.complete();
          await releasePartialCleanup.future;
        }
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Trigger a partial reset retry via pair() and pause it mid-cleanup.
      final Future<PairingInfo> retryingPair = service.pair(
        Uri.parse('wc:retry@2?relay-protocol=irn&symKey=def'),
      );
      final Future<void> retryingPairExpectation = expectLater(
        retryingPair,
        throwsStateError,
      );
      await partialCleanupStarted.future;

      // Queue a full disconnectEverything() behind the running partial reset.
      final Future<void> fullResetFuture = service.disconnectEverything();

      // An incoming proposal on an unrelated pairing must be IMMEDIATELY
      // rejected even while the partial reset is still running.
      final ProposalData proposal = ProposalData(
        id: 701,
        expiry: now + 300,
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
        pairingTopic: 'other-p2',
      );
      onSessionProposal.broadcast(SessionProposalEvent(701, proposal));
      await Future<void>.delayed(Duration.zero);

      final VerificationResult rejected = verify(
        () => walletKit.rejectSession(
          id: 701,
          reason: captureAny(named: 'reason'),
        ),
      )..called(1);
      expect(
        (rejected.captured.single as ReownSignError).code,
        equals(Errors.getSdkError(Errors.USER_REJECTED).code),
      );
      // Queued full reset must also persist fullReset: true to disk while the
      // partial reset is still running so a crash cannot lose the request.
      expect(
        persistedStorage[Web3WalletService
            .pendingResetStorageKey]?['fullReset'],
        isTrue,
      );

      // Release the partial reset: it must NOT delete the reset marker before
      // the queued full reset sweeps live-s1 and other-p2.
      releasePartialCleanup.complete();
      await fullResetFuture;
      await retryingPairExpectation;

      expect(deleteCallsBeforeFullSweep, equals(0));
      expect(activeSessions, isEmpty);
      expect(livePairings, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test(
      'does not abort an in-flight pair() when a real unrelated non-full '
      'partial reset runs concurrently, but still aborts if its topic is swept',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Completer<void> pairNewStarted = Completer<void>();
        final Completer<void> releasePairNew = Completer<void>();
        final Completer<void> partialCleanupStarted = Completer<void>();
        final Completer<void> releasePartialCleanup = Completer<void>();

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
        when(() => crypto.deleteSymKey('old-p1')).thenAnswer((_) async {
          if (!partialCleanupStarted.isCompleted) {
            partialCleanupStarted.complete();
            await releasePartialCleanup.future;
          }
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          if (topic == 'new-p2') {
            if (!pairNewStarted.isCompleted) {
              pairNewStarted.complete();
            }
            await releasePairNew.future;
          }
          return PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        // Start pair() for 'new-p2' and pause inside walletKit.pair().
        final Future<PairingInfo> pairNewFuture = service.pair(
          Uri.parse('wc:new-p2@2?relay-protocol=irn&symKey=def'),
        );
        await pairNewStarted.future;

        // Trigger a REAL non-full partial reset targeting 'old-p1' via a second
        // pair() call while 'new-p2' is in flight (_isResetting == true).
        persistedStorage[Web3WalletService.pendingResetStorageKey] =
            <String, dynamic>{
              'pending': true,
              'fullReset': false,
              'pendingPairings': <String>['old-p1'],
            };
        final Future<PairingInfo> triggeringPair = service.pair(
          Uri.parse('wc:other-p3@2?relay-protocol=irn&symKey=ghi'),
        );
        await partialCleanupStarted.future;

        // Release 'new-p2' WHILE the partial reset is actively running
        // (_isResetting == true): it must succeed instead of aborting.
        releasePairNew.complete();
        final PairingInfo result = await pairNewFuture;
        expect(result.topic, equals('new-p2'));

        releasePartialCleanup.complete();
        final PairingInfo triggerResult = await triggeringPair;
        expect(triggerResult.topic, equals('other-p3'));

        // Opposite case: if a real partial reset sweeps the SAME topic
        // ('swept-p1') and completes while pair('swept-p1') is in flight,
        // pair('swept-p1') MUST abort via sweptTopicsDuringPair.
        final Completer<void> sweptPairStarted = Completer<void>();
        final Completer<void> releaseSweptPair = Completer<void>();
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          if (topic == 'swept-p1') {
            if (!sweptPairStarted.isCompleted) {
              sweptPairStarted.complete();
            }
            await releaseSweptPair.future;
          }
          return PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
        });

        final Future<PairingInfo> sweptPairFuture = service.pair(
          Uri.parse('wc:swept-p1@2?relay-protocol=irn&symKey=jkl'),
        );
        await sweptPairStarted.future;

        persistedStorage[Web3WalletService.pendingResetStorageKey] =
            <String, dynamic>{
              'pending': true,
              'fullReset': false,
              'pendingPairings': <String>['swept-p1'],
            };
        // Complete a real partial reset targeting 'swept-p1' (marker cleared).
        final PairingInfo otherAfterSweep = await service.pair(
          Uri.parse('wc:after-sweep@2?relay-protocol=irn&symKey=mno'),
        );
        expect(otherAfterSweep.topic, equals('after-sweep'));
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );

        releaseSweptPair.complete();
        await expectLater(sweptPairFuture, throwsStateError);
      },
    );

    test('overlapping pair() stale-pairing cleanup does not disconnect a topic '
        'recreated by a concurrent pair()', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'orphan-a',
          expiry: now + 300,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
        PairingInfo(
          topic: 'orphan-b',
          expiry: now + 300,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      ];
      final Completer<void> orphanADisconnectStarted = Completer<void>();
      final Completer<void> releaseOrphanADisconnect = Completer<void>();
      int orphanBDisconnects = 0;

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'orphan-a')).thenAnswer((_) async {
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-a');
        if (!orphanADisconnectStarted.isCompleted) {
          orphanADisconnectStarted.complete();
          await releaseOrphanADisconnect.future;
        }
      });
      when(() => pairing.disconnect(topic: 'orphan-b')).thenAnswer((_) async {
        orphanBDisconnects++;
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-b');
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
        Invocation i,
      ) async {
        final Uri uri = i.namedArguments[#uri] as Uri;
        final String topic = uri.path.split('@').first;
        final PairingInfo created = PairingInfo(
          topic: topic,
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings
          ..removeWhere((PairingInfo p) => p.topic == topic)
          ..add(created);
        return created;
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Call A snapshots [orphan-a, orphan-b] and pauses while disconnecting
      // orphan-a.
      final Future<PairingInfo> callAFuture = service.pair(
        Uri.parse('wc:fresh-a@2?relay-protocol=irn&symKey=111'),
      );
      await orphanADisconnectStarted.future;

      // Call B recreates orphan-b (still inactive until proposal arrives) and
      // completes while Call A is still paused.
      final PairingInfo recreatedB = await service.pair(
        Uri.parse('wc:orphan-b@2?relay-protocol=irn&symKey=222'),
      );
      expect(recreatedB.topic, equals('orphan-b'));
      final int orphanBDisconnectsAfterCallB = orphanBDisconnects;

      // Resume Call A: it must skip the newly recreated orphan-b instead of
      // disconnecting it based on its stale snapshot.
      releaseOrphanADisconnect.complete();
      final PairingInfo createdA = await callAFuture;
      expect(createdA.topic, equals('fresh-a'));

      expect(orphanBDisconnects, equals(orphanBDisconnectsAfterCallB));
      expect(
        livePairings.map((PairingInfo p) => p.topic),
        containsAll(<String>['orphan-b', 'fresh-a']),
      );
    });

    test('overlapping pair() stale-pairing cleanup skips a topic with an '
        'active in-flight pair() call', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'orphan-a',
          expiry: now + 300,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
        PairingInfo(
          topic: 'orphan-c',
          expiry: now + 300,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      ];
      final Completer<void> orphanADisconnectStarted = Completer<void>();
      final Completer<void> releaseOrphanADisconnect = Completer<void>();
      final Completer<void> callCPairStarted = Completer<void>();
      final Completer<void> releaseCallCPair = Completer<void>();
      int orphanCDisconnects = 0;

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'orphan-a')).thenAnswer((_) async {
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-a');
        if (!orphanADisconnectStarted.isCompleted) {
          orphanADisconnectStarted.complete();
          await releaseOrphanADisconnect.future;
        }
      });
      when(() => pairing.disconnect(topic: 'orphan-c')).thenAnswer((_) async {
        orphanCDisconnects++;
        livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-c');
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
        Invocation i,
      ) async {
        final Uri uri = i.namedArguments[#uri] as Uri;
        final String topic = uri.path.split('@').first;
        final PairingInfo created = PairingInfo(
          topic: topic,
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings
          ..removeWhere((PairingInfo p) => p.topic == topic)
          ..add(created);
        if (topic == 'orphan-c') {
          if (!callCPairStarted.isCompleted) {
            callCPairStarted.complete();
          }
          await releaseCallCPair.future;
        }
        return created;
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      final Future<PairingInfo> callAFuture = service.pair(
        Uri.parse('wc:fresh-a@2?relay-protocol=irn&symKey=111'),
      );
      await orphanADisconnectStarted.future;

      final Future<PairingInfo> callCFuture = service.pair(
        Uri.parse('wc:orphan-c@2?relay-protocol=irn&symKey=333'),
      );
      await callCPairStarted.future;
      final int orphanCDisconnectsAfterCallCStart = orphanCDisconnects;

      releaseOrphanADisconnect.complete();
      final PairingInfo createdA = await callAFuture;
      expect(createdA.topic, equals('fresh-a'));

      releaseCallCPair.complete();
      final PairingInfo createdC = await callCFuture;
      expect(createdC.topic, equals('orphan-c'));

      expect(orphanCDisconnects, equals(orphanCDisconnectsAfterCallCStart));
      expect(
        livePairings.map((PairingInfo p) => p.topic),
        containsAll(<String>['orphan-c', 'fresh-a']),
      );
    });

    test(
      'preserves relay reconnect flag when a second reset starts while '
      'recovery disconnect is pending and awaits reconnect before pair()',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final Completer<void> sdkPairStarted = Completer<void>();
        final Completer<void> relaySubscribeResponse = Completer<void>();
        final Completer<void> relayDisconnectCompleter = Completer<void>();
        final Completer<void> secondResetWriteStarted = Completer<void>();
        final Completer<void> releaseSecondResetWrite = Completer<void>();
        final Completer<void> relayConnectCompleter = Completer<void>();
        bool holdNextMarkerWrite = false;
        bool walletKitPairCalledAfterReset = false;

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
          if (holdNextMarkerWrite) {
            holdNextMarkerWrite = false;
            if (!secondResetWriteStarted.isCompleted) {
              secondResetWriteStarted.complete();
            }
            await releaseSecondResetWrite.future;
          }
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          persistedStorage.remove(i.positionalArguments[0] as String);
        });
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'hung-r1')).thenAnswer((_) async {
          livePairings.clear();
        });
        when(() => relayClient.disconnect()).thenAnswer((_) {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.completeError(
              StateError('relay socket closing'),
            );
          }
          return relayDisconnectCompleter.future;
        });
        when(
          () => relayClient.connect(),
        ).thenAnswer((_) => relayConnectCompleter.future);
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          final PairingInfo created = PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          if (topic == 'hung-r1') {
            livePairings.add(created);
            if (!sdkPairStarted.isCompleted) {
              sdkPairStarted.complete();
            }
            await relaySubscribeResponse.future;
          } else {
            walletKitPairCalledAfterReset = true;
          }
          return created;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.complete();
          }
          if (!relayDisconnectCompleter.isCompleted) {
            relayDisconnectCompleter.complete();
          }
          if (!releaseSecondResetWrite.isCompleted) {
            releaseSecondResetWrite.complete();
          }
          if (!relayConnectCompleter.isCompleted) {
            relayConnectCompleter.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Future<PairingInfo> hungPairFuture = service.pair(
          Uri.parse('wc:hung-r1@2?relay-protocol=irn&symKey=def'),
        );
        final Future<void> hungPairExpectation = expectLater(
          hungPairFuture,
          throwsStateError,
        );
        await sdkPairStarted.future;

        await expectLater(
          service.disconnectEverything(),
          throwsA(isA<TimeoutException>()),
        );

        // Recovery reset completes while relayClient.disconnect() is still
        // pending, leaving _reconnectRelayAfterRecovery waiting on it.
        await service.disconnectEverything();
        await hungPairExpectation;
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => relayClient.connect());

        // Start a second disconnectEverything() while recovery disconnect is
        // still pending, and let recovery disconnect settle mid-reset.
        holdNextMarkerWrite = true;
        final Future<void> secondResetFuture = service.disconnectEverything();
        await secondResetWriteStarted.future;

        relayDisconnectCompleter.complete();
        await Future<void>.delayed(Duration.zero);
        // Must NOT reconnect while the second reset is active.
        verifyNever(() => relayClient.connect());

        // Once the second reset completes, it must reconnect the relay because
        // _needsRelayReconnectAfterRecovery was preserved.
        releaseSecondResetWrite.complete();
        await secondResetFuture;
        await Future<void>.delayed(Duration.zero);
        verify(() => relayClient.connect()).called(1);

        // A pair() started while relayClient.connect() is still in flight must
        // await reconnection before calling walletKit.pair().
        final Future<PairingInfo> postResetPair = service.pair(
          Uri.parse('wc:after-reconnect@2?relay-protocol=irn&symKey=xyz'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(walletKitPairCalledAfterReset, isFalse);

        relayConnectCompleter.complete();
        final PairingInfo created = await postResetPair;
        expect(created.topic, equals('after-reconnect'));
        expect(walletKitPairCalledAfterReset, isTrue);
      },
    );

    test(
      'bounds hung disconnectSession in _disconnectUnsupportedSessions so '
      'init() completes, purges locally, and drains pending requests',
      () async {
        final Completer<void> hungUnsupportedDisconnect = Completer<void>();
        activeSessions['bad-hung'] = _buildSession(
          topic: 'bad-hung',
          chainId: 'zenon:42',
          selfPublicKey: 'pk-bad-hung',
        );
        activeSessions['good-s1'] = _buildSession(topic: 'good-s1');
        pendingRequests['901'] = const SessionRequest(
          id: 901,
          topic: 'good-s1',
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
          () => walletKit.disconnectSession(
            topic: 'bad-hung',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) => hungUnsupportedDisconnect.future);
        when(() => sessionStore.delete('bad-hung')).thenAnswer((_) async {
          activeSessions.remove('bad-hung');
        });
        when(
          () => nomService.handleZnnInfo(
            'good-s1',
            null,
            requestId: 901,
            verifyContext: any(named: 'verifyContext'),
          ),
        ).thenAnswer((_) async => <String, dynamic>{'address': 'z1...'});

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!hungUnsupportedDisconnect.isCompleted) {
            hungUnsupportedDisconnect.complete();
          }
          await service.onDispose();
        });
        service.create();

        await service.init().timeout(const Duration(seconds: 2));
        await Future<void>.delayed(Duration.zero);

        verify(() => sessionStore.delete('bad-hung')).called(1);
        verify(() => crypto.deleteKeyPair('pk-bad-hung')).called(1);
        verify(() => crypto.deleteSymKey('bad-hung')).called(1);
        verify(() => expirer.delete('bad-hung')).called(1);
        verifyNever(() => relayClient.unsubscribe(topic: 'bad-hung'));
        expect(activeSessions.keys, equals(<String>['good-s1']));
        verify(
          () => walletKit.respondSessionRequest(
            topic: 'good-s1',
            response: any(named: 'response'),
          ),
        ).called(1);
      },
    );

    test(
      'bounds hung single-session disconnectSession with local purge fallback '
      'and rethrows if local purge fails',
      () async {
        final Completer<void> hungSingleDisconnect = Completer<void>();
        activeSessions['single-hung'] = _buildSession(
          topic: 'single-hung',
          selfPublicKey: 'pk-single-hung',
        );
        activeSessions['single-purge-fail'] = _buildSession(
          topic: 'single-purge-fail',
          selfPublicKey: 'pk-single-fail',
        );

        when(
          () => walletKit.disconnectSession(
            topic: 'single-hung',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) => hungSingleDisconnect.future);
        when(() => sessionStore.delete('single-hung')).thenAnswer((_) async {
          activeSessions.remove('single-hung');
        });
        when(
          () => walletKit.disconnectSession(
            topic: 'single-purge-fail',
            reason: any(named: 'reason'),
          ),
        ).thenThrow(StateError('relay offline'));
        when(
          () => sessionStore.delete('single-purge-fail'),
        ).thenThrow(StateError('storage write error'));

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!hungSingleDisconnect.isCompleted) {
            hungSingleDisconnect.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        await service
            .disconnectSession(topic: 'single-hung')
            .timeout(const Duration(seconds: 2));

        verify(() => sessionStore.delete('single-hung')).called(1);
        verify(() => crypto.deleteKeyPair('pk-single-hung')).called(1);
        verify(() => crypto.deleteSymKey('single-hung')).called(1);
        verify(() => expirer.delete('single-hung')).called(1);
        verifyNever(() => relayClient.unsubscribe(topic: 'single-hung'));
        expect(
          service.sessions.value.map((SessionData s) => s.topic),
          equals(<String>['single-purge-fail']),
        );

        await expectLater(
          service.disconnectSession(topic: 'single-purge-fail'),
          throwsStateError,
        );
      },
    );

    test(
      'full reset shares a single relay timeout budget across many hung '
      'sessions and pairings instead of waiting N * timeout serially',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final List<Completer<void>> hungOps = <Completer<void>>[];

        for (int i = 0; i < 6; i++) {
          final String sTopic = 'hung-s-$i';
          activeSessions[sTopic] = _buildSession(
            topic: sTopic,
            selfPublicKey: 'pk-$i',
          );
          final String pTopic = 'hung-p-$i';
          livePairings.add(
            PairingInfo(
              topic: pTopic,
              expiry: now + 3600,
              relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
              active: true,
            ),
          );
        }

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        int disconnectStarts = 0;
        when(
          () => walletKit.disconnectSession(
            topic: any(named: 'topic'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) {
          disconnectStarts++;
          final Completer<void> c = Completer<void>();
          hungOps.add(c);
          return c.future;
        });
        when(() => sessionStore.delete(any())).thenAnswer((Invocation i) async {
          // By the time the first local purge runs, all 6 remote disconnects
          // must have already been launched concurrently in parallel.
          expect(disconnectStarts, equals(6));
          activeSessions.remove(i.positionalArguments[0] as String);
        });
        when(() => pairing.disconnect(topic: any(named: 'topic'))).thenAnswer((
          Invocation i,
        ) async {
          final String topic = i.namedArguments[#topic] as String;
          livePairings.removeWhere((PairingInfo p) => p.topic == topic);
        });
        when(
          () => relayClient.unsubscribe(topic: any(named: 'topic')),
        ).thenAnswer((_) {
          final Completer<void> c = Completer<void>();
          hungOps.add(c);
          return c.future;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 80),
        );
        addTearDown(() async {
          for (final Completer<void> c in hungOps) {
            if (!c.isCompleted) {
              c.complete();
            }
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Stopwatch sw = Stopwatch()..start();
        await service.disconnectEverything();
        sw.stop();

        // 12 hung items serially would take >= 960ms; under a single shared
        // 80ms budget it completes well below 500ms.
        expect(sw.elapsedMilliseconds, lessThan(500));
        expect(activeSessions, isEmpty);
        expect(livePairings, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test(
      'refreshes sessions.value on late onSessionDelete even while timed-out '
      'disconnectSession operation is still tracked',
      () async {
        final Completer<void> hungDisconnect = Completer<void>();
        activeSessions['stale-s1'] = _buildSession(
          topic: 'stale-s1',
          selfPublicKey: 'pk-stale-1',
        );

        when(
          () => walletKit.disconnectSession(
            topic: 'stale-s1',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) => hungDisconnect.future);
        // Simulate local purge failing so stale-s1 remains in activeSessions
        // and service.sessions.value after disconnectSession times out.
        when(
          () => sessionStore.delete('stale-s1'),
        ).thenThrow(StateError('local delete failed'));

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!hungDisconnect.isCompleted) {
            hungDisconnect.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        await expectLater(
          service.disconnectSession(topic: 'stale-s1'),
          throwsA(isA<TimeoutException>()),
        );
        expect(
          service.sessions.value.map((SessionData s) => s.topic),
          equals(<String>['stale-s1']),
        );

        // Late SDK _deleteSession removes the session from the store and
        // broadcasts onSessionDelete BEFORE hungDisconnect completes.
        activeSessions.remove('stale-s1');
        onSessionDelete.broadcast(SessionDelete('stale-s1'));

        expect(service.sessions.value, isEmpty);

        hungDisconnect.complete();
        await Future<void>.delayed(Duration.zero);
        expect(service.sessions.value, isEmpty);
      },
    );

    test(
      'bounds wait for a hung approveSession() call and recovers on retry by '
      'disconnecting the relay, sweeping the session, and reconnecting',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        const MethodChannel windowManagerChannel = MethodChannel(
          'window_manager',
        );
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(windowManagerChannel, (
              MethodCall call,
            ) async {
              if (call.method == 'isFocused' || call.method == 'isVisible') {
                return true;
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(windowManagerChannel, null);
        });

        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Completer<void> sdkApproveStarted = Completer<void>();
        final Completer<void> relaySubscribeResponse = Completer<void>();

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
        when(() => relayClient.disconnect()).thenAnswer((_) async {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.completeError(
              StateError('relay socket closed'),
            );
          }
        });
        when(
          () => walletKit.disconnectSession(
            topic: 'stuck-s1',
            reason: any(named: 'reason'),
          ),
        ).thenThrow(StateError('relay disconnected'));
        when(() => sessionStore.delete('stuck-s1')).thenAnswer((_) async {
          activeSessions.remove('stuck-s1');
        });
        when(
          () => walletKit.approveSession(
            id: any(named: 'id'),
            namespaces: any(named: 'namespaces'),
          ),
        ).thenAnswer((_) async {
          final SessionData created = _buildSession(
            topic: 'stuck-s1',
            selfPublicKey: 'pk-stuck-s1',
          );
          activeSessions['stuck-s1'] = created;
          if (!sdkApproveStarted.isCompleted) {
            sdkApproveStarted.complete();
          }
          await relaySubscribeResponse.future;
          return ApproveResponse(topic: 'stuck-s1', session: created);
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Future<ApproveResponse> hungApprove = service.approveSession(
          id: 801,
          namespaces: const <String, Namespace>{},
          pairingTopic: 'p-801',
        );
        final Future<void> hungApproveExpectation = expectLater(
          hungApprove,
          throwsStateError,
        );
        await sdkApproveStarted.future;

        await expectLater(
          service.disconnectEverything(),
          throwsA(isA<TimeoutException>()),
        );
        verifyNever(() => relayClient.disconnect());
        expect(
          persistedStorage[Web3WalletService
              .pendingResetStorageKey]?['fullReset'],
          isTrue,
        );

        await service.disconnectEverything();
        await hungApproveExpectation;
        await Future<void>.delayed(Duration.zero);

        verify(() => relayClient.disconnect()).called(1);
        verify(() => relayClient.connect()).called(1);
        verify(() => crypto.deleteKeyPair('pk-stuck-s1')).called(1);
        verify(() => crypto.deleteSymKey('stuck-s1')).called(1);
        verify(() => expirer.delete('stuck-s1')).called(1);
        expect(activeSessions, isEmpty);
        expect(
          persistedStorage.containsKey(
            Web3WalletService.pendingResetStorageKey,
          ),
          isFalse,
        );
      },
    );

    test('pair() waits for an in-flight stale-pairing disconnect on the same '
        'topic so cleanup cannot delete the newly created pairing', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'race-topic',
          expiry: now + 300,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      ];
      final Completer<void> disconnectStarted = Completer<void>();
      final Completer<void> releaseDisconnect = Completer<void>();
      bool walletKitPairStartedForRaceTopic = false;

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'race-topic')).thenAnswer((_) async {
        if (!disconnectStarted.isCompleted) {
          disconnectStarted.complete();
          await releaseDisconnect.future;
        }
        // Mirrors Reown deleting the topic AFTER awaiting _isValidDisconnect.
        livePairings.removeWhere((PairingInfo p) => p.topic == 'race-topic');
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
        Invocation i,
      ) async {
        final Uri uri = i.namedArguments[#uri] as Uri;
        final String topic = uri.path.split('@').first;
        if (topic == 'race-topic') {
          walletKitPairStartedForRaceTopic = true;
        }
        final PairingInfo created = PairingInfo(
          topic: topic,
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings
          ..removeWhere((PairingInfo p) => p.topic == topic)
          ..add(created);
        return created;
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      // Call A starts stale-pairing disconnect for 'race-topic' and pauses
      // mid-disconnect (before Reown removes 'race-topic' from pairings).
      final Future<PairingInfo> callAFuture = service.pair(
        Uri.parse('wc:other-a@2?relay-protocol=irn&symKey=111'),
      );
      await disconnectStarted.future;

      // Call B attempts to pair 'race-topic' while Call A's disconnect is
      // still in flight: Call B must wait for Call A's disconnect to settle
      // BEFORE invoking walletKit.pair('race-topic').
      final Future<PairingInfo> callBFuture = service.pair(
        Uri.parse('wc:race-topic@2?relay-protocol=irn&symKey=222'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(walletKitPairStartedForRaceTopic, isFalse);

      releaseDisconnect.complete();
      await callAFuture;
      final PairingInfo createdB = await callBFuture;
      expect(createdB.topic, equals('race-topic'));
      expect(walletKitPairStartedForRaceTopic, isTrue);
      expect(
        livePairings.map((PairingInfo p) => p.topic),
        contains('race-topic'),
      );
    });

    test(
      'starts the shared relay sweep budget lazily after in-flight pair() '
      'settlement so session disconnects still get the full timeout budget',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Completer<void> sdkPairStarted = Completer<void>();
        bool sessionDisconnectCompletedRemotely = false;

        activeSessions['slow-ok-s1'] = _buildSession(
          topic: 'slow-ok-s1',
          selfPublicKey: 'pk-slow-ok',
        );

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
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          _,
        ) async {
          if (!sdkPairStarted.isCompleted) {
            sdkPairStarted.complete();
          }
          // Consumes most of a single 300ms timeout before settling.
          await Future<void>.delayed(const Duration(milliseconds: 220));
          return PairingInfo(
            topic: 'slow-pair',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
        });
        when(
          () => walletKit.disconnectSession(
            topic: 'slow-ok-s1',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) async {
          // Takes 160ms: would time out if the 300ms budget had started before
          // waiting 220ms on the in-flight pair() call (220 + 160 = 380ms >
          // 300ms), while leaving 140ms of CI headroom when lazy.
          await Future<void>.delayed(const Duration(milliseconds: 160));
          activeSessions.remove('slow-ok-s1');
          sessionDisconnectCompletedRemotely = true;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        final Future<PairingInfo> slowPair = service.pair(
          Uri.parse('wc:slow-pair@2?relay-protocol=irn&symKey=def'),
        );
        final Future<void> slowPairExpectation = expectLater(
          slowPair,
          throwsStateError,
        );
        await sdkPairStarted.future;

        await service.disconnectEverything();
        await slowPairExpectation;

        expect(sessionDisconnectCompletedRemotely, isTrue);
        verifyNever(() => sessionStore.delete('slow-ok-s1'));
        expect(activeSessions, isEmpty);
      },
    );

    test(
      'registers requested topic before pre-pair awaits so a concurrent '
      'stale-pairing cleanup resuming mid-microtask cannot delete it',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final List<PairingInfo> livePairings = <PairingInfo>[
          PairingInfo(
            topic: 'orphan-x',
            expiry: now + 300,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          ),
          PairingInfo(
            topic: 'topic-t',
            expiry: now + 300,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          ),
        ];
        final Completer<void> orphanXDisconnectStarted = Completer<void>();
        final Completer<void> releaseOrphanXDisconnect = Completer<void>();
        final Completer<void> topicTDisconnectFinish = Completer<void>();
        bool protectTopicTWithProposal = true;
        bool releaseOrphanXOnNextReload = false;
        int topicTDisconnectCalls = 0;

        when(pairingStore.getAll).thenAnswer((_) {
          // _cleanupStalePairings ends with _reloadStores(), which calls
          // pairingStore.getAll(). Schedule two microtasks later so Call B
          // resumes from _cleanupStalePairings and is yielding inside its
          // pre-pair awaits (_awaitPendingRecoveryRelayReconnect /
          // _awaitInFlightStaleCleanupDisconnects) when Call A wakes up and
          // advances to topic-t.
          if (releaseOrphanXOnNextReload &&
              !releaseOrphanXDisconnect.isCompleted) {
            releaseOrphanXOnNextReload = false;
            scheduleMicrotask(
              () => scheduleMicrotask(() {
                protectTopicTWithProposal = false;
                if (!releaseOrphanXDisconnect.isCompleted) {
                  releaseOrphanXDisconnect.complete();
                }
              }),
            );
          }
          return List<PairingInfo>.from(livePairings);
        });
        when(() => walletKit.getPendingSessionProposals()).thenAnswer((_) {
          if (!protectTopicTWithProposal) {
            return const <String, ProposalData>{};
          }
          // Call B skips topic-t during its own cleanup; mark next getAll()
          // (_reloadStores() at end of Call B's cleanup) to release Call A.
          if (orphanXDisconnectStarted.isCompleted) {
            releaseOrphanXOnNextReload = true;
          }
          return <String, ProposalData>{
            '99': ProposalData(
              id: 99,
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
              pairingTopic: 'topic-t',
            ),
          };
        });
        when(() => pairing.disconnect(topic: 'orphan-x')).thenAnswer((_) async {
          livePairings.removeWhere((PairingInfo p) => p.topic == 'orphan-x');
          if (!orphanXDisconnectStarted.isCompleted) {
            orphanXDisconnectStarted.complete();
            await releaseOrphanXDisconnect.future;
          }
        });
        when(() => pairing.disconnect(topic: 'topic-t')).thenAnswer((_) async {
          topicTDisconnectCalls++;
          await topicTDisconnectFinish.future;
          livePairings.removeWhere((PairingInfo p) => p.topic == 'topic-t');
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          if (topic == 'topic-t') {
            expect(releaseOrphanXDisconnect.isCompleted, isTrue);
          }
          final PairingInfo created = PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings
            ..removeWhere((PairingInfo p) => p.topic == topic)
            ..add(created);
          return created;
        });

        final Web3WalletService service = buildService();
        addTearDown(() async {
          if (!releaseOrphanXDisconnect.isCompleted) {
            releaseOrphanXDisconnect.complete();
          }
          if (!topicTDisconnectFinish.isCompleted) {
            topicTDisconnectFinish.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        // Call A snapshots [orphan-x, topic-t] and pauses on orphan-x.
        final Future<PairingInfo> callAFuture = service.pair(
          Uri.parse('wc:other-a@2?relay-protocol=irn&symKey=111'),
        );
        unawaited(callAFuture.then<void>((_) {}, onError: (Object _) {}));
        await orphanXDisconnectStarted.future;

        // Call B targets topic-t. As Call B finishes _cleanupStalePairings and
        // yields on its pre-pair awaits, Call A resumes and reaches topic-t.
        final PairingInfo createdB = await service.pair(
          Uri.parse('wc:topic-t@2?relay-protocol=irn&symKey=222'),
        );
        if (!topicTDisconnectFinish.isCompleted) {
          topicTDisconnectFinish.complete();
        }
        await callAFuture;

        expect(createdB.topic, equals('topic-t'));
        expect(topicTDisconnectCalls, equals(0));
        expect(
          livePairings.map((PairingInfo p) => p.topic),
          contains('topic-t'),
        );
      },
    );

    test('blocks pair() before SDK admission when disconnectEverything() '
        'starts during a no-op pre-pair await microtask', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{};
      late final Web3WalletService service;
      int getAllCallsDuringPair = 0;
      bool armed = false;
      Future<void>? resetFuture;

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
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer(
        (_) async => PairingInfo(
          topic: 'pre-pair-reset',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        ),
      );
      when(pairingStore.getAll).thenAnswer((_) {
        // Call 1 is the opening snapshot in _cleanupStalePairings; Call 2 is
        // _reloadStores() at the tail of _cleanupStalePairings. Scheduling two
        // microtasks from Call 2 fires disconnectEverything() AFTER pair()'s
        // post-cleanup guard passes and while pair() yields inside its no-op
        // pre-pair awaits (directly exercising the final admission guard).
        if (armed) {
          getAllCallsDuringPair++;
          if (getAllCallsDuringPair == 2) {
            armed = false;
            scheduleMicrotask(
              () => scheduleMicrotask(() {
                resetFuture = service.disconnectEverything();
              }),
            );
          }
        }
        return const <PairingInfo>[];
      });

      service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      armed = true;
      await expectLater(
        service.pair(
          Uri.parse('wc:pre-pair-reset@2?relay-protocol=irn&symKey=def'),
        ),
        throwsStateError,
      );
      expect(getAllCallsDuringPair, equals(2));
      expect(resetFuture, isNotNull);
      await resetFuture;

      verifyNever(() => walletKit.pair(uri: any(named: 'uri')));
    });

    test(
      'blocks SDK admission when disconnectAllPairings() sweeps the requested '
      'topic during pre-pair waits, but allows unrelated topic sweeps',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final List<PairingInfo> livePairings = <PairingInfo>[];
        final Completer<void> sdkPairStarted = Completer<void>();
        final Completer<void> relaySubscribeResponse = Completer<void>();
        Completer<void> relayConnectCompleter = Completer<void>();
        int sdkPairCallsForTarget = 0;

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
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: any(named: 'topic'))).thenAnswer((
          Invocation i,
        ) async {
          final String topic = i.namedArguments[#topic] as String;
          livePairings.removeWhere((PairingInfo p) => p.topic == topic);
        });
        when(() => relayClient.disconnect()).thenAnswer((_) async {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.completeError(
              StateError('relay socket closed'),
            );
          }
        });
        when(
          () => relayClient.connect(),
        ).thenAnswer((_) => relayConnectCompleter.future);
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          final PairingInfo created = PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          if (topic == 'hung-seed') {
            livePairings.add(created);
            if (!sdkPairStarted.isCompleted) {
              sdkPairStarted.complete();
            }
            await relaySubscribeResponse.future;
          } else if (topic == 'swept-t' || topic == 'allowed-t') {
            sdkPairCallsForTarget++;
            livePairings.add(created);
          }
          return created;
        });

        final Web3WalletService service = Web3WalletService(
          walletKit: walletKit,
          chainResolver: (String _) => nomService,
          inFlightPairWaitTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(() async {
          if (!relaySubscribeResponse.isCompleted) {
            relaySubscribeResponse.complete();
          }
          if (!relayConnectCompleter.isCompleted) {
            relayConnectCompleter.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        // Trigger a recovery reset that leaves relayClient.connect() pending so
        // the next pair() pauses inside _awaitPendingRecoveryRelayReconnect().
        final Future<PairingInfo> hungSeed = service.pair(
          Uri.parse('wc:hung-seed@2?relay-protocol=irn&symKey=def'),
        );
        final Future<void> hungSeedExpectation = expectLater(
          hungSeed,
          throwsStateError,
        );
        await sdkPairStarted.future;
        await expectLater(
          service.disconnectEverything(),
          throwsA(isA<TimeoutException>()),
        );
        await service.disconnectEverything();
        await hungSeedExpectation;

        // Case 1: Sweeping the requested topic 'swept-t' during the reconnect
        // wait must stop pair() before SDK admission.
        livePairings.add(
          PairingInfo(
            topic: 'swept-t',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        );
        final Future<PairingInfo> sweptPairFuture = service.pair(
          Uri.parse('wc:swept-t@2?relay-protocol=irn&symKey=aaa'),
        );
        await Future<void>.delayed(Duration.zero);

        await service.disconnectAllPairings();
        relayConnectCompleter.complete();

        await expectLater(
          sweptPairFuture,
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('pairing was aborted'),
            ),
          ),
        );
        expect(sdkPairCallsForTarget, equals(0));
        expect(livePairings, isEmpty);

        // Case 2: Sweeping an unrelated topic 'unrelated-u' during the wait
        // must NOT stop pair() for 'allowed-t'.
        final Completer<void> secondSubscribe = Completer<void>();
        final Completer<void> secondSeedStarted = Completer<void>();
        relayConnectCompleter = Completer<void>();
        when(() => relayClient.disconnect()).thenAnswer((_) async {
          if (!secondSubscribe.isCompleted) {
            secondSubscribe.completeError(StateError('relay socket closed'));
          }
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          final PairingInfo created = PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          if (topic == 'hung-seed-2') {
            livePairings.add(created);
            if (!secondSeedStarted.isCompleted) {
              secondSeedStarted.complete();
            }
            await secondSubscribe.future;
          } else if (topic == 'allowed-t') {
            sdkPairCallsForTarget++;
            livePairings.add(created);
          }
          return created;
        });

        final Future<PairingInfo> hungSeed2 = service.pair(
          Uri.parse('wc:hung-seed-2@2?relay-protocol=irn&symKey=def'),
        );
        final Future<void> hungSeed2Expectation = expectLater(
          hungSeed2,
          throwsStateError,
        );
        await secondSeedStarted.future;
        await expectLater(
          service.disconnectEverything(),
          throwsA(isA<TimeoutException>()),
        );
        await service.disconnectEverything();
        await hungSeed2Expectation;

        livePairings.add(
          PairingInfo(
            topic: 'unrelated-u',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        );
        final Future<PairingInfo> allowedPairFuture = service.pair(
          Uri.parse('wc:allowed-t@2?relay-protocol=irn&symKey=bbb'),
        );
        await Future<void>.delayed(Duration.zero);

        await service.disconnectAllPairings();
        relayConnectCompleter.complete();

        final PairingInfo created = await allowedPairFuture;
        expect(created.topic, equals('allowed-t'));
        expect(sdkPairCallsForTarget, equals(1));
      },
    );

    test(
      'blocks topic reuse while disconnectAllPairings() owns the topic before '
      'batch unsubscribe finishes, then allows reuse afterward',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final List<PairingInfo> livePairings = <PairingInfo>[
          PairingInfo(
            topic: 'sweep-t',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
          PairingInfo(
            topic: 'sweep-u',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          ),
        ];
        final Completer<void> uDisconnectStarted = Completer<void>();
        final Completer<void> releaseUDisconnect = Completer<void>();
        final Completer<void> tUnsubscribeStarted = Completer<void>();
        final Completer<void> releaseTUnsubscribe = Completer<void>();
        int uDisconnectCalls = 0;

        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => pairing.disconnect(topic: 'sweep-t')).thenAnswer((_) async {
          livePairings.removeWhere((PairingInfo p) => p.topic == 'sweep-t');
        });
        when(() => pairing.disconnect(topic: 'sweep-u')).thenAnswer((_) async {
          uDisconnectCalls++;
          if (!uDisconnectStarted.isCompleted) {
            uDisconnectStarted.complete();
            await releaseUDisconnect.future;
          }
          livePairings.removeWhere((PairingInfo p) => p.topic == 'sweep-u');
        });
        when(() => relayClient.unsubscribe(topic: 'sweep-t')).thenAnswer((
          _,
        ) async {
          if (!tUnsubscribeStarted.isCompleted) {
            tUnsubscribeStarted.complete();
            await releaseTUnsubscribe.future;
          }
        });
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
          Invocation i,
        ) async {
          final Uri uri = i.namedArguments[#uri] as Uri;
          final String topic = uri.path.split('@').first;
          final PairingInfo created = PairingInfo(
            topic: topic,
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          );
          livePairings.add(created);
          return created;
        });

        final Web3WalletService service = buildService();
        addTearDown(() async {
          if (!releaseUDisconnect.isCompleted) {
            releaseUDisconnect.complete();
          }
          if (!releaseTUnsubscribe.isCompleted) {
            releaseTUnsubscribe.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        // Start sweep: removes sweep-t locally and pauses on inactive sweep-u
        // (still visible in store) BEFORE the batch unsubscribe for sweep-t
        // has run.
        final Future<void> sweepFuture = service.disconnectAllPairings();
        await uDisconnectStarted.future;

        // Re-pairing sweep-t must be rejected while owned by the active sweep.
        await expectLater(
          service.pair(Uri.parse('wc:sweep-t@2?relay-protocol=irn&symKey=aaa')),
          throwsStateError,
        );
        verifyNever(() => walletKit.pair(uri: any(named: 'uri')));

        // Unrelated topic must skip sweep-owned inactive sweep-u during stale
        // cleanup (no duplicate disconnect) and proceed immediately.
        final PairingInfo other = await service.pair(
          Uri.parse('wc:unrelated-v@2?relay-protocol=irn&symKey=bbb'),
        );
        expect(other.topic, equals('unrelated-v'));
        expect(uDisconnectCalls, equals(1));

        // Release sweep-u so the batch unsubscribe for sweep-t begins and stays
        // pending: sweep-t must still be rejected before SDK admission.
        releaseUDisconnect.complete();
        await tUnsubscribeStarted.future;
        await expectLater(
          service.pair(Uri.parse('wc:sweep-t@2?relay-protocol=irn&symKey=aaa')),
          throwsStateError,
        );
        verifyNever(
          () => walletKit.pair(
            uri: Uri.parse('wc:sweep-t@2?relay-protocol=irn&symKey=aaa'),
          ),
        );

        // Once the sweep finishes its batch unsubscribe, sweep-t can be reused.
        releaseTUnsubscribe.complete();
        await sweepFuture;

        final PairingInfo reused = await service.pair(
          Uri.parse('wc:sweep-t@2?relay-protocol=irn&symKey=aaa'),
        );
        expect(reused.topic, equals('sweep-t'));
      },
    );

    test(
      'retries pending single-session local cleanup with the saved public key '
      'when the session record was already deleted',
      () async {
        activeSessions['keyfail-s1'] = _buildSession(
          topic: 'keyfail-s1',
          selfPublicKey: 'pk-saved-1',
        );
        bool failKeyPairDeleteOnce = true;

        when(
          () => walletKit.disconnectSession(
            topic: 'keyfail-s1',
            reason: any(named: 'reason'),
          ),
        ).thenThrow(StateError('relay offline'));
        when(() => sessionStore.delete('keyfail-s1')).thenAnswer((_) async {
          activeSessions.remove('keyfail-s1');
        });
        when(() => crypto.deleteKeyPair('pk-saved-1')).thenAnswer((_) async {
          if (failKeyPairDeleteOnce) {
            failKeyPairDeleteOnce = false;
            throw StateError('keychain temporarily locked');
          }
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        // Attempt 1 deletes the session record but fails deleting the key pair.
        await expectLater(
          service.disconnectSession(topic: 'keyfail-s1'),
          throwsStateError,
        );
        expect(activeSessions, isEmpty);

        // Attempt 2 must retry local cleanup directly with the saved public key
        // without repeating the remote disconnectSession call or skipping
        // deleteKeyPair.
        await service.disconnectSession(topic: 'keyfail-s1');
        verify(() => crypto.deleteKeyPair('pk-saved-1')).called(2);
        verify(
          () => walletKit.disconnectSession(
            topic: 'keyfail-s1',
            reason: any(named: 'reason'),
          ),
        ).called(1);

        // Once retry succeeds, the pending entry is cleared so a subsequent
        // call does not repeat deleteKeyPair for the already-deleted key.
        await service.disconnectSession(topic: 'keyfail-s1');
        verifyNever(() => crypto.deleteKeyPair('pk-saved-1'));
      },
    );

    test('rejects a pre-reset proposal when a full reset completes while '
        'windowManager.isFocused() is pending', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const MethodChannel windowManagerChannel = MethodChannel(
        'window_manager',
      );
      final Completer<void> focusCheckStarted = Completer<void>();
      final Completer<bool> releaseFocusCheck = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowManagerChannel, (
            MethodCall call,
          ) async {
            if (call.method == 'isFocused') {
              if (!focusCheckStarted.isCompleted) {
                focusCheckStarted.complete();
              }
              return await releaseFocusCheck.future;
            }
            if (call.method == 'isVisible') {
              return true;
            }
            return null;
          });
      addTearDown(() {
        if (!releaseFocusCheck.isCompleted) {
          releaseFocusCheck.complete(true);
        }
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(windowManagerChannel, null);
      });

      final Web3WalletService service = buildService();
      addTearDown(service.onDispose);
      service.create();
      await service.init();

      final ProposalData proposal = ProposalData(
        id: 951,
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
        pairingTopic: 'p-951',
      );

      onSessionProposal.broadcast(SessionProposalEvent(951, proposal));
      await focusCheckStarted.future;

      // Complete a full reset while windowManager.isFocused() is pending.
      await service.disconnectEverything();

      // Release focus check: stale pre-reset proposal must be rejected.
      releaseFocusCheck.complete(true);
      await Future<void>.delayed(Duration.zero);

      final VerificationResult rejected = verify(
        () => walletKit.rejectSession(
          id: 951,
          reason: captureAny(named: 'reason'),
        ),
      )..called(1);
      expect(
        (rejected.captured.single as ReownSignError).code,
        equals(Errors.getSdkError(Errors.USER_REJECTED).code),
      );
    });

    test(
      'preserves unresolved full-reset flags when a second '
      'disconnectEverything arrives while the first reset clears its marker',
      () async {
        final Map<String, Map<String, dynamic>> persistedStorage =
            <String, Map<String, dynamic>>{};
        final Completer<void> firstDeleteStarted = Completer<void>();
        final Completer<void> releaseFirstDelete = Completer<void>();
        final Completer<void> secondPersistStarted = Completer<void>();
        final Completer<void> releaseSecondPersist = Completer<void>();
        int setCalls = 0;

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
          setCalls++;
          if (setCalls == 2) {
            if (!secondPersistStarted.isCompleted) {
              secondPersistStarted.complete();
            }
            await releaseSecondPersist.future;
          }
          persistedStorage[i.positionalArguments[0]
              as String] = Map<String, dynamic>.from(
            i.positionalArguments[1] as Map<String, dynamic>,
          );
        });
        when(() => coreStorage.delete(any())).thenAnswer((Invocation i) async {
          if (!firstDeleteStarted.isCompleted) {
            firstDeleteStarted.complete();
            await releaseFirstDelete.future;
          }
          persistedStorage.remove(i.positionalArguments[0] as String);
        });

        final Web3WalletService service = buildService();
        addTearDown(() async {
          if (!releaseFirstDelete.isCompleted) {
            releaseFirstDelete.complete();
          }
          if (!releaseSecondPersist.isCompleted) {
            releaseSecondPersist.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Future<void> firstReset = service.disconnectEverything();
        await firstDeleteStarted.future;

        // Queue a second full reset while the first is awaiting marker delete.
        final Future<void> secondReset = service.disconnectEverything();

        // Release first delete: it must NOT clear _hasUnresolvedFullReset while
        // the second reset is waiting to persist its marker.
        releaseFirstDelete.complete();
        await firstReset;
        await secondPersistStarted.future;

        final ProposalData proposal = ProposalData(
          id: 961,
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
          pairingTopic: 'p-961',
        );
        onSessionProposal.broadcast(SessionProposalEvent(961, proposal));
        await Future<void>.delayed(Duration.zero);

        verify(
          () => walletKit.rejectSession(id: 961, reason: any(named: 'reason')),
        ).called(1);

        releaseSecondPersist.complete();
        await secondReset;
      },
    );

    test(
      'flushes pending keychain persist on online disconnectSession retry and '
      'keeps retry state if persist fails',
      () async {
        activeSessions['kc-s1'] = _buildSession(
          topic: 'kc-s1',
          selfPublicKey: 'pk-kc-1',
        );
        bool failRemoteOnce = true;
        int remainingKeyChainPersistFailures = 2;

        when(
          () => walletKit.disconnectSession(
            topic: 'kc-s1',
            reason: any(named: 'reason'),
          ),
        ).thenAnswer((_) async {
          if (failRemoteOnce) {
            failRemoteOnce = false;
            throw StateError('relay offline');
          }
          // Online retry removes session without flushing keychain.
          activeSessions.remove('kc-s1');
        });
        when(() => sessionStore.delete('kc-s1')).thenAnswer((_) async {});
        when(keyChainStore.persist).thenAnswer((_) async {
          if (remainingKeyChainPersistFailures > 0) {
            remainingKeyChainPersistFailures--;
            throw StateError('keychain flush failed');
          }
        });

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        // Attempt 1 (offline): fallback evicts keys in memory, fails persist
        // -> leaves _needsKeyChainPersist = true and saves pending cleanup.
        await expectLater(
          service.disconnectSession(topic: 'kc-s1'),
          throwsStateError,
        );
        // Attempt 2 (online): remote disconnect succeeds, keychain persist
        // fails once -> fallback local purge also fails persist and rethrows
        // while keeping the pending cleanup entry.
        remainingKeyChainPersistFailures = 2;
        await expectLater(
          service.disconnectSession(topic: 'kc-s1'),
          throwsStateError,
        );
        // Attempt 3: session record is gone, saved-key local retry runs and
        // succeeds once keychain persist succeeds.
        await service.disconnectSession(topic: 'kc-s1');
        verify(() => crypto.deleteKeyPair('pk-kc-1')).called(3);
      },
    );

    test(
      'absorbs unawaited async errors thrown inside core.pairing.disconnect '
      'across deactivatePairing, stale cleanup, and disconnectAllPairings '
      'without leaking secrets while still propagating direct errors',
      () async {
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final List<Object> uncaughtErrors = <Object>[];
        final List<LogRecord> logs = <LogRecord>[];
        final Logger logger = Logger('WalletConnectService');
        final Level previousLevel = logger.level;
        final bool previousHierarchical = hierarchicalLoggingEnabled;
        hierarchicalLoggingEnabled = true;
        logger.level = Level.ALL;
        final StreamSubscription<LogRecord> logSub = logger.onRecord.listen(
          logs.add,
        );
        addTearDown(() async {
          await logSub.cancel();
          logger.level = previousLevel;
          hierarchicalLoggingEnabled = previousHierarchical;
        });

        final List<PairingInfo> livePairings = <PairingInfo>[
          PairingInfo(
            topic: 'stale-unawaited',
            expiry: now + 300,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          ),
          PairingInfo(
            topic: 'reset-unawaited',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: true,
          ),
        ];
        when(
          pairingStore.getAll,
        ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
        when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer(
          (_) async => PairingInfo(
            topic: 'fresh-pair',
            expiry: now + 3600,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          ),
        );

        when(() => pairing.disconnect(topic: 'deact-unawaited')).thenAnswer((
          _,
        ) async {
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => Future<void>.error(
                StateError('relay failed symKey=super-secret-deact'),
              ),
            ),
          );
        });
        when(() => pairing.disconnect(topic: 'stale-unawaited')).thenAnswer((
          _,
        ) async {
          livePairings.removeWhere(
            (PairingInfo p) => p.topic == 'stale-unawaited',
          );
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => Future<void>.error(
                const ReownCoreError(
                  code: 9001,
                  message: 'wc:secret-uri@2?symKey=super-secret-stale',
                ),
              ),
            ),
          );
        });
        when(() => pairing.disconnect(topic: 'reset-unawaited')).thenAnswer((
          _,
        ) async {
          livePairings.removeWhere(
            (PairingInfo p) => p.topic == 'reset-unawaited',
          );
          unawaited(
            Future<void>.delayed(
              Duration.zero,
              () => Future<void>.error(
                StateError('jwt=super-secret-reset-token'),
              ),
            ),
          );
        });
        when(() => pairing.disconnect(topic: 'direct-fail')).thenAnswer(
          (_) => Future<void>.error(
            const ReownCoreError(code: 1001, message: 'No matching pairing'),
          ),
        );

        final Web3WalletService service = buildService();
        addTearDown(service.onDispose);
        service.create();
        await service.init();

        await runZonedGuarded(
          () async {
            await service.deactivatePairing(topic: 'deact-unawaited');
            await service.pair(
              Uri.parse('wc:fresh-pair@2?relay-protocol=irn&symKey=abc'),
            );
            await service.disconnectAllPairings();

            await expectLater(
              service.deactivatePairing(topic: 'direct-fail'),
              throwsA(
                isA<ReownCoreError>().having(
                  (ReownCoreError e) => e.code,
                  'code',
                  1001,
                ),
              ),
            );

            await Future<void>.delayed(const Duration(milliseconds: 20));
          },
          (Object error, StackTrace _) {
            uncaughtErrors.add(error);
          },
        );

        expect(uncaughtErrors, isEmpty);
        final List<String> suppressedMessages = logs
            .where(
              (LogRecord r) => r.message.contains('Suppressed unawaited async'),
            )
            .map((LogRecord r) => r.message)
            .toList();
        expect(suppressedMessages, hasLength(3));
        expect(
          suppressedMessages.any(
            (String m) =>
                m.contains('deact-unawaited') && m.contains('StateError'),
          ),
          isTrue,
        );
        expect(
          suppressedMessages.any(
            (String m) =>
                m.contains('stale-unawaited') &&
                m.contains('ReownCoreError(code=9001)'),
          ),
          isTrue,
        );
        expect(
          suppressedMessages.any(
            (String m) =>
                m.contains('reset-unawaited') && m.contains('StateError'),
          ),
          isTrue,
        );
        for (final LogRecord record in logs) {
          expect(record.message, isNot(contains('super-secret')));
          expect(record.message, isNot(contains('symKey=')));
        }
      },
    );

    test('gates standalone disconnectSession against pending and in-flight '
        'full resets without touching stores or reloading', () async {
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

      // Case 1: Pre-init disconnectEverything() leaves a pending reset;
      // standalone disconnectSession must be rejected immediately.
      final Web3WalletService preInitService = buildService();
      addTearDown(preInitService.onDispose);
      preInitService.create();
      await preInitService.disconnectEverything();

      await expectLater(
        preInitService.disconnectSession(topic: 'pre-init-s1'),
        throwsStateError,
      );
      verifyNever(
        () => walletKit.disconnectSession(
          topic: 'pre-init-s1',
          reason: any(named: 'reason'),
        ),
      );
      verifyNever(() => sessionStore.delete('pre-init-s1'));

      // Case 2: In-flight initialized full reset rejects concurrent standalone
      // disconnectSession without overlapping store deletes or _reloadStores().
      persistedStorage.clear();
      activeSessions['reset-s1'] = _buildSession(
        topic: 'reset-s1',
        selfPublicKey: 'pk-reset-1',
      );
      activeSessions['other-s2'] = _buildSession(
        topic: 'other-s2',
        selfPublicKey: 'pk-other-2',
      );
      final Completer<void> resetRemoteStarted = Completer<void>();
      final Completer<void> releaseResetRemote = Completer<void>();

      when(
        () => walletKit.disconnectSession(
          topic: 'reset-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        if (!resetRemoteStarted.isCompleted) {
          resetRemoteStarted.complete();
        }
        await releaseResetRemote.future;
        activeSessions.remove('reset-s1');
      });
      when(
        () => walletKit.disconnectSession(
          topic: 'other-s2',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        activeSessions.remove('other-s2');
      });

      final Web3WalletService service = buildService();
      addTearDown(() async {
        if (!releaseResetRemote.isCompleted) {
          releaseResetRemote.complete();
        }
        await service.onDispose();
      });
      service.create();
      await service.init();

      final Future<void> resetFuture = service.disconnectEverything();
      await resetRemoteStarted.future;

      await expectLater(
        service.disconnectSession(topic: 'other-s2'),
        throwsStateError,
      );

      releaseResetRemote.complete();
      await resetFuture;

      // Only the full reset invoked disconnectSession for other-s2 (once).
      verify(
        () => walletKit.disconnectSession(
          topic: 'other-s2',
          reason: any(named: 'reason'),
        ),
      ).called(1);
      expect(activeSessions, isEmpty);

      // Case 3: Once reset completes, standalone disconnectSession works again.
      activeSessions['post-s3'] = _buildSession(
        topic: 'post-s3',
        selfPublicKey: 'pk-post-3',
      );
      when(
        () => walletKit.disconnectSession(
          topic: 'post-s3',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {
        activeSessions.remove('post-s3');
      });
      await service.disconnectSession(topic: 'post-s3');
      expect(activeSessions, isEmpty);
    });

    test('interrupts an in-flight standalone disconnectSession when '
        'disconnectEverything starts and hands off cleanup cleanly', () async {
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

      activeSessions['s-race'] = _buildSession(
        topic: 's-race',
        selfPublicKey: 'pk-race',
      );
      final Completer<void> remoteStarted = Completer<void>();
      final Completer<void> hungRemote = Completer<void>();

      when(
        () => walletKit.disconnectSession(
          topic: 's-race',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) {
        if (!remoteStarted.isCompleted) {
          remoteStarted.complete();
        }
        return hungRemote.future;
      });
      when(() => sessionStore.delete('s-race')).thenAnswer((_) async {
        activeSessions.remove('s-race');
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(seconds: 2),
      );
      addTearDown(() async {
        if (!hungRemote.isCompleted) {
          hungRemote.completeError(StateError('late hung disconnect'));
        }
        await service.onDispose();
      });
      service.create();
      await service.init();

      final Future<void> standaloneFuture = service.disconnectSession(
        topic: 's-race',
      );
      final Future<void> standaloneExpectation = expectLater(
        standaloneFuture,
        throwsStateError,
      );
      await remoteStarted.future;

      final Stopwatch sw = Stopwatch()..start();
      await service.disconnectEverything();
      sw.stop();
      await standaloneExpectation;

      // Reset interrupted standalone disconnectSession immediately rather than
      // waiting for its 2s relay timeout or firing a duplicate remote call.
      expect(sw.elapsedMilliseconds, lessThan(500));
      verify(
        () => walletKit.disconnectSession(
          topic: 's-race',
          reason: any(named: 'reason'),
        ),
      ).called(1);
      verify(() => sessionStore.delete('s-race')).called(1);
      verify(() => crypto.deleteKeyPair('pk-race')).called(1);
      verify(() => crypto.deleteSymKey('s-race')).called(1);
      verify(() => expirer.delete('s-race')).called(1);
      expect(activeSessions, isEmpty);
      expect(service.sessions.value, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
    });

    test(
      'serializes disconnectEverything behind an in-flight standalone '
      'disconnectSession local purge so store deletes never overlap',
      () async {
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

        activeSessions['s-purge'] = _buildSession(
          topic: 's-purge',
          selfPublicKey: 'pk-purge',
        );
        activeSessions['s-second'] = _buildSession(
          topic: 's-second',
          selfPublicKey: 'pk-second',
        );
        final Completer<void> deleteStarted = Completer<void>();
        final Completer<void> releaseDelete = Completer<void>();
        int activeStoreDeletes = 0;
        int maxConcurrentStoreDeletes = 0;

        when(
          () => walletKit.disconnectSession(
            topic: 's-purge',
            reason: any(named: 'reason'),
          ),
        ).thenThrow(StateError('relay offline'));
        when(
          () => walletKit.disconnectSession(
            topic: 's-second',
            reason: any(named: 'reason'),
          ),
        ).thenThrow(StateError('relay offline'));
        when(() => sessionStore.delete(any())).thenAnswer((Invocation i) async {
          final String topic = i.positionalArguments[0] as String;
          activeStoreDeletes++;
          if (activeStoreDeletes > maxConcurrentStoreDeletes) {
            maxConcurrentStoreDeletes = activeStoreDeletes;
          }
          try {
            if (topic == 's-purge' && !deleteStarted.isCompleted) {
              deleteStarted.complete();
              await releaseDelete.future;
            }
            activeSessions.remove(topic);
          } finally {
            activeStoreDeletes--;
          }
        });

        final Web3WalletService service = buildService();
        addTearDown(() async {
          if (!releaseDelete.isCompleted) {
            releaseDelete.complete();
          }
          await service.onDispose();
        });
        service.create();
        await service.init();

        final Future<void> standaloneFuture = service.disconnectSession(
          topic: 's-purge',
        );
        final Future<void> standaloneExpectation = expectLater(
          standaloneFuture,
          throwsStateError,
        );
        await deleteStarted.future;

        // Start full reset while standalone disconnectSession is inside
        // sessionStore.delete('s-purge'). Full reset must wait before sweeping
        // any sessions.
        final Future<void> resetFuture = service.disconnectEverything();
        await Future<void>.delayed(Duration.zero);
        verifyNever(
          () => walletKit.disconnectSession(
            topic: 's-second',
            reason: any(named: 'reason'),
          ),
        );
        expect(maxConcurrentStoreDeletes, equals(1));

        releaseDelete.complete();
        await resetFuture;
        await standaloneExpectation;

        expect(maxConcurrentStoreDeletes, equals(1));
        expect(activeSessions, isEmpty);
        expect(service.sessions.value, isEmpty);
      },
    );

    test('bounds hung core.pairing.disconnect in _cleanupStalePairings so '
        'pair() does not stall and blocks reuse of the hung topic until '
        'settled', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        for (int i = 0; i < 4; i++)
          PairingInfo(
            topic: 'stale-$i',
            expiry: now + 300,
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            active: false,
          ),
      ];
      final Completer<Error?> hungStaleDisconnect = Completer<Error?>();

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(() => pairing.disconnect(topic: 'stale-0')).thenAnswer((_) async {
        final Error? error = await hungStaleDisconnect.future;
        if (error != null) {
          throw error;
        }
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
        Invocation i,
      ) async {
        final Uri uri = i.namedArguments[#uri] as Uri;
        final String topic = uri.path.split('@').first;
        final PairingInfo created = PairingInfo(
          topic: topic,
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings
          ..removeWhere((PairingInfo p) => p.topic == topic)
          ..add(created);
        return created;
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(milliseconds: 60),
      );
      addTearDown(() async {
        if (!hungStaleDisconnect.isCompleted) {
          hungStaleDisconnect.complete(null);
        }
        await service.onDispose();
      });
      service.create();
      await service.init();

      final Stopwatch sw = Stopwatch()..start();
      final PairingInfo paired = await service.pair(
        Uri.parse('wc:fresh-p1@2?relay-protocol=irn&symKey=111'),
      );
      sw.stop();

      expect(paired.topic, equals('fresh-p1'));
      expect(sw.elapsedMilliseconds, lessThan(400));
      verify(() => pairing.disconnect(topic: 'stale-0')).called(1);
      verifyNever(() => pairing.disconnect(topic: 'stale-1'));
      verifyNever(() => pairing.disconnect(topic: 'stale-2'));
      verifyNever(() => pairing.disconnect(topic: 'stale-3'));

      // Re-pairing the hung topic while its disconnect is still pending must
      // be rejected without admitting walletKit.pair('stale-0').
      await expectLater(
        service.pair(Uri.parse('wc:stale-0@2?relay-protocol=irn&symKey=222')),
        throwsStateError,
      );
      verifyNever(
        () => walletKit.pair(
          uri: Uri.parse('wc:stale-0@2?relay-protocol=irn&symKey=222'),
        ),
      );
      // Subsequent stale cleanup must skip stale-0 rather than launching a
      // duplicate disconnect while the first one is still in flight.
      verifyNever(() => pairing.disconnect(topic: 'stale-0'));

      // Once the hung disconnect settles (even with an error), no unhandled
      // error escapes and stale-0 can be paired cleanly.
      livePairings.removeWhere((PairingInfo p) => p.topic == 'stale-0');
      hungStaleDisconnect.complete(StateError('late stale failure'));
      await Future<void>.delayed(Duration.zero);

      final PairingInfo repaired = await service.pair(
        Uri.parse('wc:stale-0@2?relay-protocol=irn&symKey=222'),
      );
      expect(repaired.topic, equals('stale-0'));
    });

    test('tracks skipped relay unsubscriptions separately from local reset '
        'cleanup when shared budget is exhausted and reconciles them on relay '
        'reconnect', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final Map<String, Map<String, dynamic>> persistedStorage =
          <String, Map<String, dynamic>>{};
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'budget-p1',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
        PairingInfo(
          topic: 'budget-p2',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ];
      activeSessions['budget-s1'] = _buildSession(
        topic: 'budget-s1',
        selfPublicKey: 'pk-bs1',
      );
      activeSessions['budget-s2'] = _buildSession(
        topic: 'budget-s2',
        selfPublicKey: 'pk-bs2',
      );

      final Completer<void> s1Completer = Completer<void>();
      final Completer<void> s2Completer = Completer<void>();

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
      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(
        () => walletKit.disconnectSession(
          topic: 'budget-s1',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) => s1Completer.future);
      when(
        () => walletKit.disconnectSession(
          topic: 'budget-s2',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) => s2Completer.future);
      when(() => sessionStore.delete(any())).thenAnswer((Invocation i) async {
        activeSessions.remove(i.positionalArguments[0] as String);
      });
      when(() => pairing.disconnect(topic: any(named: 'topic'))).thenAnswer((
        Invocation i,
      ) async {
        final String topic = i.namedArguments[#topic] as String;
        livePairings.removeWhere((PairingInfo p) => p.topic == topic);
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(milliseconds: 60),
      );
      addTearDown(() async {
        if (!s1Completer.isCompleted) s1Completer.complete();
        if (!s2Completer.isCompleted) s2Completer.complete();
        await service.onDispose();
      });
      service.create();
      await service.init();

      await service.disconnectEverything();

      // Local deletion succeeded and reset marker is cleared, while all 4
      // skipped relay unsubscriptions are tracked separately for reconnect.
      expect(activeSessions, isEmpty);
      expect(livePairings, isEmpty);
      expect(
        persistedStorage.containsKey(Web3WalletService.pendingResetStorageKey),
        isFalse,
      );
      verifyNever(() => relayClient.unsubscribe(topic: any(named: 'topic')));
      expect(
        service.pendingRelayUnsubscriptionTopics,
        equals(<String>{'budget-s1', 'budget-s2', 'budget-p1', 'budget-p2'}),
      );

      // Settle s1's timed-out disconnectSession while s2 remains pending.
      s1Completer.completeError(StateError('socket closed'));
      await Future<void>.delayed(Duration.zero);

      // Reconnect 1 reconciles p1, p2, and s1, while deferring s2 until its
      // timed-out operation settles.
      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      verify(() => relayClient.unsubscribe(topic: 'budget-p1')).called(1);
      verify(() => relayClient.unsubscribe(topic: 'budget-p2')).called(1);
      verify(() => relayClient.unsubscribe(topic: 'budget-s1')).called(1);
      verifyNever(() => relayClient.unsubscribe(topic: 'budget-s2'));
      expect(
        service.pendingRelayUnsubscriptionTopics,
        equals(<String>{'budget-s2'}),
      );

      // Settle s2 and reconnect again: s2 is now reconciled and previously
      // reconciled topics are not unsubscribed a second time.
      s2Completer.completeError(StateError('socket closed'));
      await Future<void>.delayed(Duration.zero);

      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      verify(() => relayClient.unsubscribe(topic: 'budget-s2')).called(1);
      verifyNever(() => relayClient.unsubscribe(topic: 'budget-p1'));
      verifyNever(() => relayClient.unsubscribe(topic: 'budget-p2'));
      verifyNever(() => relayClient.unsubscribe(topic: 'budget-s1'));
      expect(service.pendingRelayUnsubscriptionTopics, isEmpty);
    });

    test('never unsubscribes a replacement pairing or session of the same '
        'topic during delayed reconnect reconciliation', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'reused-p',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
        PairingInfo(
          topic: 'stale-p',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ];
      activeSessions['reused-s'] = _buildSession(
        topic: 'reused-s',
        selfPublicKey: 'pk-rs1',
      );
      final Completer<void> hungSession = Completer<void>();

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(
        () => walletKit.disconnectSession(
          topic: 'reused-s',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) => hungSession.future);
      when(() => sessionStore.delete('reused-s')).thenAnswer((_) async {
        activeSessions.remove('reused-s');
      });
      when(() => pairing.disconnect(topic: any(named: 'topic'))).thenAnswer((
        Invocation i,
      ) async {
        final String topic = i.namedArguments[#topic] as String;
        livePairings.removeWhere((PairingInfo p) => p.topic == topic);
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
        Invocation i,
      ) async {
        final Uri uri = i.namedArguments[#uri] as Uri;
        final String topic = uri.path.split('@').first;
        final PairingInfo created = PairingInfo(
          topic: topic,
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings.add(created);
        return created;
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(milliseconds: 60),
      );
      addTearDown(() async {
        if (!hungSession.isCompleted) hungSession.complete();
        await service.onDispose();
      });
      service.create();
      await service.init();

      await service.disconnectEverything();
      expect(
        service.pendingRelayUnsubscriptionTopics,
        equals(<String>{'reused-s', 'reused-p', 'stale-p'}),
      );

      // Old hung disconnect settles before replacement session connects.
      hungSession.completeError(StateError('old socket closed'));
      await Future<void>.delayed(Duration.zero);

      // Create a replacement pairing for 'reused-p' and replacement session
      // for 'reused-s' before the relay reconnects.
      await service.pair(
        Uri.parse('wc:reused-p@2?relay-protocol=irn&symKey=replacement-key'),
      );
      final SessionData replacementSession = _buildSession(
        topic: 'reused-s',
        selfPublicKey: 'pk-rs-replacement',
      );
      activeSessions['reused-s'] = replacementSession;
      onSessionConnect.broadcast(SessionConnect(replacementSession));

      // Reconnect must only unsubscribe 'stale-p' and NEVER touch 'reused-p'
      // or 'reused-s'.
      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);

      verify(() => relayClient.unsubscribe(topic: 'stale-p')).called(1);
      verifyNever(() => relayClient.unsubscribe(topic: 'reused-p'));
      verifyNever(() => relayClient.unsubscribe(topic: 'reused-s'));
      expect(service.pendingRelayUnsubscriptionTopics, isEmpty);
    });

    test('waits for an in-flight reconcile unsubscribe before admitting '
        'replacement pair() on the same topic and does not re-queue failed '
        'obsolete unsubscribes', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'race-reconcile',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ];
      activeSessions['budget-burn-s'] = _buildSession(
        topic: 'budget-burn-s',
        selfPublicKey: 'pk-burn',
      );
      final Completer<void> burnSession = Completer<void>();
      final Completer<void> reconcileStarted = Completer<void>();
      final Completer<void> releaseReconcile = Completer<void>();
      bool walletKitPairStarted = false;

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(
        () => walletKit.disconnectSession(
          topic: 'budget-burn-s',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) => burnSession.future);
      when(() => sessionStore.delete('budget-burn-s')).thenAnswer((_) async {
        activeSessions.remove('budget-burn-s');
      });
      when(() => pairing.disconnect(topic: 'race-reconcile')).thenAnswer((
        _,
      ) async {
        livePairings.clear();
      });
      when(() => relayClient.unsubscribe(topic: 'race-reconcile')).thenAnswer((
        _,
      ) async {
        if (!reconcileStarted.isCompleted) {
          reconcileStarted.complete();
        }
        await releaseReconcile.future;
      });
      when(() => walletKit.pair(uri: any(named: 'uri'))).thenAnswer((
        Invocation i,
      ) async {
        walletKitPairStarted = true;
        final Uri uri = i.namedArguments[#uri] as Uri;
        final String topic = uri.path.split('@').first;
        final PairingInfo created = PairingInfo(
          topic: topic,
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: false,
        );
        livePairings.add(created);
        return created;
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(milliseconds: 200),
      );
      addTearDown(() async {
        if (!burnSession.isCompleted) burnSession.complete();
        if (!releaseReconcile.isCompleted) releaseReconcile.complete();
        await service.onDispose();
      });
      service.create();
      await service.init();

      await service.disconnectEverything();
      expect(
        service.pendingRelayUnsubscriptionTopics,
        contains('race-reconcile'),
      );

      // Start reconnect reconciliation and pause mid-unsubscribe.
      onRelayConnect.broadcast(EventArgs());
      await reconcileStarted.future;

      // Replacement pair() for the same topic must wait for the in-flight
      // unsubscribe to finish before calling walletKit.pair().
      final Future<PairingInfo> replacementPair = service.pair(
        Uri.parse('wc:race-reconcile@2?relay-protocol=irn&symKey=new'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(walletKitPairStarted, isFalse);

      // Fail the old in-flight unsubscribe: replacement pair() proceeds and
      // the obsolete failed unsubscribe must NOT be re-queued.
      releaseReconcile.completeError(StateError('transient relay error'));
      final PairingInfo created = await replacementPair;
      expect(created.topic, equals('race-reconcile'));
      expect(walletKitPairStarted, isTrue);

      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);
      verify(() => relayClient.unsubscribe(topic: 'race-reconcile')).called(1);
      expect(
        service.pendingRelayUnsubscriptionTopics,
        isNot(contains('race-reconcile')),
      );
    });

    test('retries transient reconcile unsubscribe failure on subsequent '
        'reconnect and preserves pending topic epochs across >256 unrelated '
        'pairings', () async {
      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<PairingInfo> livePairings = <PairingInfo>[
        PairingInfo(
          topic: 'retry-p',
          expiry: now + 3600,
          relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
          active: true,
        ),
      ];
      activeSessions['burn-s'] = _buildSession(
        topic: 'burn-s',
        selfPublicKey: 'pk-burn',
      );
      final Completer<void> burnSession = Completer<void>();
      bool failFirstReconcile = true;

      when(
        pairingStore.getAll,
      ).thenAnswer((_) => List<PairingInfo>.from(livePairings));
      when(
        () => walletKit.disconnectSession(
          topic: 'burn-s',
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) => burnSession.future);
      when(() => sessionStore.delete('burn-s')).thenAnswer((_) async {
        activeSessions.remove('burn-s');
      });
      when(() => pairing.disconnect(topic: 'retry-p')).thenAnswer((_) async {
        livePairings.clear();
      });
      when(() => relayClient.unsubscribe(topic: 'retry-p')).thenAnswer((
        _,
      ) async {
        if (failFirstReconcile) {
          failFirstReconcile = false;
          throw StateError('transient reconnect drop');
        }
      });

      final Web3WalletService service = Web3WalletService(
        walletKit: walletKit,
        chainResolver: (String _) => nomService,
        inFlightPairWaitTimeout: const Duration(milliseconds: 60),
      );
      addTearDown(() async {
        if (!burnSession.isCompleted) burnSession.complete();
        await service.onDispose();
      });
      service.create();
      await service.init();

      await service.disconnectEverything();
      expect(service.pendingRelayUnsubscriptionTopics, contains('retry-p'));

      // Exceed _maxTrackedPairingEpochs (256) with unrelated pairings.
      for (int i = 0; i < 270; i++) {
        onPairingCreate.broadcast(PairingEvent(topic: 'unrelated-$i'));
      }

      // First reconnect fails transiently -> topic remains pending.
      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);
      verify(() => relayClient.unsubscribe(topic: 'retry-p')).called(1);
      expect(service.pendingRelayUnsubscriptionTopics, contains('retry-p'));

      // Second reconnect succeeds -> topic is reconciled and cleared.
      onRelayConnect.broadcast(EventArgs());
      await Future<void>.delayed(Duration.zero);
      verify(() => relayClient.unsubscribe(topic: 'retry-p')).called(1);
      expect(
        service.pendingRelayUnsubscriptionTopics,
        isNot(contains('retry-p')),
      );
    });
  });
}
