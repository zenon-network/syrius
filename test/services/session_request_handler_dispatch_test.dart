import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reown_core/connectivity/i_connectivity.dart';
import 'package:reown_core/models/tvf_data.dart';
import 'package:reown_core/pairing/i_pairing.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/services/desktop_signing_wallet_kit.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_request_utils.dart';

class _OnlineConnectivity implements IConnectivity {
  @override
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {
    isOnline.dispose();
  }
}

/// Captures handlers registered on [IPairing.register] so we can exercise
/// upstream [ReownSign]'s real `wc_sessionPropose` and `wc_sessionRequest`
/// paths without opening a network relay connection.
class _StubPairing implements IPairing {
  @override
  final Event<PairingEvent> onPairingCreate = Event<PairingEvent>();
  @override
  final Event<PairingActivateEvent> onPairingActivate =
      Event<PairingActivateEvent>();
  @override
  final Event<PairingEvent> onPairingPing = Event<PairingEvent>();
  @override
  final Event<PairingInvalidEvent> onPairingInvalid =
      Event<PairingInvalidEvent>();
  @override
  final Event<PairingEvent> onPairingDelete = Event<PairingEvent>();
  @override
  final Event<PairingEvent> onPairingExpire = Event<PairingEvent>();

  final Map<String, Function(String, JsonRpcRequest, [String?, TransportType])>
  handlers =
      <String, Function(String, JsonRpcRequest, [String?, TransportType])>{};
  final List<JsonRpcResponse<dynamic>> sentResponses =
      <JsonRpcResponse<dynamic>>[];

  @override
  void register({
    required String method,
    required Function(String, JsonRpcRequest, [String?, TransportType])
    function,
    required ProtocolType type,
  }) {
    handlers[method] = function;
  }

  @override
  PairingInfo? getPairing({required String topic}) => null;

  @override
  Future<void> isValidPairingTopic({required String topic}) async {}

  @override
  Future<void> updateMetadata({
    required String topic,
    required PairingMetadata metadata,
  }) async {}

  @override
  Future<void> setReceiverPublicKey({
    required String topic,
    required String publicKey,
    int? expiry,
  }) async {}

  @override
  Future<void> sendResult(
    int id,
    String topic,
    String method,
    dynamic result, {
    EncodeOptions? encodeOptions,
    String? appLink,
    TVFData? tvf,
  }) async {
    sentResponses.add(
      JsonRpcResponse<dynamic>(id: id, result: result),
    );
  }

  @override
  Future<void> sendError(
    int id,
    String topic,
    String method,
    JsonRpcError error, {
    EncodeOptions? encodeOptions,
    RpcOptions? rpcOptions,
    String? appLink,
    TVFData? tvf,
  }) async {
    sentResponses.add(
      JsonRpcResponse<dynamic>(id: id, error: error),
    );
  }

  @override
  Future<void> init() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('upstream ReownSign null-handler session request flow', () {
    test(
      'registerRequestHandler(handler: null) passes session proposal namespace '
      'conformance and emits onSessionRequest with request id for direct '
      'respondSessionRequest',
      () async {
        final ReownCore core = ReownCore(
          projectId: 'synthetic-project-id',
          memoryStore: true,
        );
        final _StubPairing stubPairing = _StubPairing();
        final _OnlineConnectivity connectivity = _OnlineConnectivity();
        core
          ..pairing = stubPairing
          ..connectivity = connectivity;
        await core.storage.init();
        await core.expirer.init();
        await core.connectivity.init();

        final DesktopSigningWalletKit kit = DesktopSigningWalletKit(
          core: core,
          metadata: const PairingMetadata(
            name: 's y r i u s',
            description: 'Test wallet',
            url: 'https://zenon.network',
          ),
        )
          // Register methods with no handler (default null) using the
          // zero-vendoring pattern.
          ..registerEventEmitter(
            chainId: 'zenon:1',
            event: 'addressChange',
          )
          ..registerRequestHandler(
            chainId: 'zenon:1',
            method: 'znn_sign',
          )
          ..registerAccount(
            chainId: 'zenon:1',
            accountAddress: 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
          );

        await kit.reOwnSign.init();

        // 1. Verify a dApp proposal requiring znn_sign passes namespace
        // generation and emits onSessionProposal instead of failing
        // conformance.
        final List<SessionProposalEvent> proposals = <SessionProposalEvent>[];
        kit.onSessionProposal.subscribe((SessionProposalEvent? event) {
          if (event != null) {
            proposals.add(event);
          }
        });

        final Function(
          String,
          JsonRpcRequest, [
          String?,
          TransportType,
        ])?
        onPropose = stubPairing.handlers[MethodConstants.WC_SESSION_PROPOSE];
        expect(onPropose, isNotNull);

        await onPropose!(
          'pairing-topic-1',
          JsonRpcRequest(
            id: 100,
            method: MethodConstants.WC_SESSION_PROPOSE,
            params: WcSessionProposeRequest(
              relays: <Relay>[Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL)],
              proposer: const ConnectionMetadata(
                publicKey: 'peer-key',
                metadata: PairingMetadata(
                  name: 'Test dApp',
                  description: 'dApp',
                  url: 'https://example.invalid',
                ),
              ),
              requiredNamespaces: <String, RequiredNamespace>{
                'zenon': const RequiredNamespace(
                  chains: <String>['zenon:1'],
                  methods: <String>['znn_sign'],
                  events: <String>['addressChange'],
                ),
              },
              optionalNamespaces: const <String, RequiredNamespace>{},
            ).toJson(),
          ),
        );

        expect(proposals, hasLength(1));
        expect(
          proposals.single.params.generatedNamespaces?['zenon']?.methods,
          contains('znn_sign'),
        );

        // 2. Seed an active session and verify an incoming wc_sessionRequest
        // emits onSessionRequest with the JSON-RPC request id.
        const String topic = 'session-topic-1';
        await kit.sessions.set(
          topic,
          SessionData(
            topic: topic,
            pairingTopic: 'pairing-topic-1',
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            acknowledged: true,
            controller: 'controller-key',
            namespaces: <String, Namespace>{
              'zenon': const Namespace(
                chains: <String>['zenon:1'],
                accounts: <String>[
                  'zenon:1:z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
                ],
                methods: <String>['znn_sign'],
                events: <String>['addressChange'],
              ),
            },
            self: const ConnectionMetadata(
              publicKey: 'self-key',
              metadata: PairingMetadata(
                name: 's y r i u s',
                description: 'Test wallet',
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
          ),
        );

        final List<SessionRequestEvent> received = <SessionRequestEvent>[];
        kit.onSessionRequest.subscribe((SessionRequestEvent? event) {
          if (event != null) {
            received.add(event);
          }
        });

        final Function(String, JsonRpcRequest, [String?, TransportType])?
        onSessionRequest =
            stubPairing.handlers[MethodConstants.WC_SESSION_REQUEST];
        expect(onSessionRequest, isNotNull);

        await onSessionRequest!(
          topic,
          JsonRpcRequest(
            id: 42,
            method: MethodConstants.WC_SESSION_REQUEST,
            params: const WcSessionRequestRequest(
              chainId: 'zenon:1',
              request: SessionRequestParams(
                method: 'znn_sign',
                params: <String, dynamic>{'message': 'hello zenon'},
              ),
            ).toJson(),
          ),
        );

        expect(received, hasLength(1));
        expect(received.single.id, 42);
        expect(received.single.topic, topic);
        expect(received.single.chainId, 'zenon:1');
        expect(received.single.method, 'znn_sign');
        expect(
          received.single.params,
          equals(<String, dynamic>{'message': 'hello zenon'}),
        );

        // 3. Verify direct respondSessionRequest delivers the result and clears
        // the pending request.
        await kit.respondSessionRequest(
          topic: topic,
          response: const JsonRpcResponse<dynamic>(
            id: 42,
            result: 'signed-signature-hex',
          ),
        );

        expect(stubPairing.sentResponses, hasLength(1));
        expect(stubPairing.sentResponses.single.id, 42);
        expect(stubPairing.sentResponses.single.result, 'signed-signature-hex');
        expect(kit.getPendingSessionRequests(), isEmpty);

        await connectivity.dispose();
      },
    );
  });

  group('walletConnectErrorToJsonRpcError', () {
    test('preserves ReownCoreError and ReownSignError codes and messages', () {
      final JsonRpcError coreErr = walletConnectErrorToJsonRpcError(
        const ReownCoreError(code: 9000, message: 'Wallet is locked'),
      );
      expect(coreErr.code, 9000);
      expect(coreErr.message, 'Wallet is locked');

      final JsonRpcError signErr = walletConnectErrorToJsonRpcError(
        const ReownSignError(code: 5000, message: 'User rejected.'),
      );
      expect(signErr.code, 5000);
      expect(signErr.message, 'User rejected.');

      final JsonRpcError rpcErr = walletConnectErrorToJsonRpcError(
        const JsonRpcError(code: 4001, message: 'Already RPC error'),
      );
      expect(rpcErr.code, 4001);
      expect(rpcErr.message, 'Already RPC error');

      final JsonRpcError genericErr = walletConnectErrorToJsonRpcError(
        UnsupportedError('Unsupported method'),
      );
      expect(genericErr.code, 5000);
      expect(genericErr.message, contains('Unsupported method'));
    });
  });
}
