import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_core/pairing/i_pairing.dart';
import 'package:reown_core/relay_client/i_relay_client.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockWalletKit extends Mock implements ReownWalletKit {}

class _MockCore extends Mock implements IReownCore {}

class _MockRelayClient extends Mock implements IRelayClient {}

class _MockPairing extends Mock implements IPairing {}

class _MockPairingStore extends Mock implements IPairingStore {}

class _MockSessionStore extends Mock implements ISessions {}

class _FakeNoMService extends Mock implements NoMService {}

SessionData _buildSession({
  required String topic,
  String chainId = 'zenon:1',
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
      when(() => walletKit.pairings).thenReturn(pairingStore);
      when(() => walletKit.sessions).thenReturn(sessionStore);

      when(
        () => relayClient.onRelayClientConnect,
      ).thenReturn(onRelayConnect);
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

    test(
      'waits for in-flight init before handling live session request and '
      'deduplicates against startup pending backlog',
      () async {
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
          () => nomService.handleZnnSign('session-1', 'hello', requestId: 77),
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
          () => nomService.handleZnnSign('session-1', 'hello', requestId: 77),
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
      },
    );

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
          () => nomService.handleZnnInfo('session-1', null, requestId: 91),
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

    test(
      'absorbs already-responded error without sending duplicate error '
      'response',
      () async {
        activeSessions['session-1'] = _buildSession(topic: 'session-1');
        when(
          () => nomService.handleZnnInfo('session-1', null, requestId: 92),
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
      },
    );

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
  });
}
