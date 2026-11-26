import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_core/crypto/i_crypto.dart';
import 'package:reown_core/events/i_events.dart';
import 'package:reown_core/heartbit/i_heartbeat.dart';
import 'package:reown_core/pairing/i_expirer.dart';
import 'package:reown_core/pairing/i_json_rpc_history.dart';
import 'package:reown_core/pairing/i_pairing.dart';
import 'package:reown_core/relay_client/i_relay_client.dart';
import 'package:reown_core/store/i_generic_store.dart';
import 'package:reown_core/store/i_store.dart';
import 'package:reown_core/verify/i_verify.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/services/desktop_signing_wallet_kit.dart';
import 'package:zenon_syrius_wallet_flutter/services/sticky_fallback_secure_store.dart';

class _Core extends Mock implements IReownCore {}

class _Store extends Mock implements IStore<Map<String, dynamic>> {}

class _Events extends Mock implements IEvents {}

class _Sign extends Mock implements IReownSign {}

class _RelayClient extends Mock implements IRelayClient {}

class _Crypto extends Mock implements ICrypto {}

class _Expirer extends Mock implements IExpirer {}

class _HeartBeat extends Mock implements IHeartBeat {}

class _Verify extends Mock implements IVerify {}

class _Pairing extends Mock implements IPairing {}

class _PairingStore extends Mock implements IPairingStore {}

class _JsonRpcHistory extends Mock implements IJsonRpcHistory {}

class _ReceiverKeyStore extends Mock
    implements IGenericStore<ReceiverPublicKey> {}

class _ProposalStore extends Mock implements IGenericStore<ProposalData> {}

class _SessionStore extends Mock implements ISessions {}

class _PendingRequestStore extends Mock
    implements IGenericStore<SessionRequest> {}

class _AuthRequestStore extends Mock
    implements IGenericStore<PendingSessionAuthRequest> {}

class _AuthKeyStore extends Mock implements IGenericStore<AuthPublicKey> {}

class _StringStore extends Mock implements IGenericStore<String> {}

class _ControlledKit extends DesktopSigningWalletKit {
  _ControlledKit(IReownCore core, this.sign)
    : super(
        core: core,
        metadata: const PairingMetadata(
          name: 'Synthetic desktop wallet',
          description: 'Offline initialization fixture',
          url: 'https://example.invalid',
        ),
      );

  final IReownSign sign;

  @override
  IReownSign get reOwnSign => sign;
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late _Core core;
  late _Events events;
  late _Sign sign;
  late _ControlledKit kit;
  late List<String> order;
  late int paymentCalls;

  setUpAll(() {
    registerFallbackValue(const PublishOptions(ttl: 0, tag: 0));
    registerFallbackValue(ProtocolType.sign);
  });

  setUp(() {
    core = _Core();
    events = _Events();
    sign = _Sign();
    order = <String>[];
    paymentCalls = 0;
    when(() => core.storage).thenReturn(_Store());
    when(() => core.events).thenReturn(events);
    when(() => core.projectId).thenReturn('synthetic-project-id');
    when(() => core.start()).thenAnswer((_) async => order.add('core'));
    when(() => events.sendStoredEvents()).thenAnswer((_) async {
      order.add('events');
    });
    when(() => sign.init()).thenAnswer((_) async => order.add('sign'));
    kit = _ControlledKit(core, sign);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('walletconnect_pay'),
      (_) async {
        paymentCalls++;
        throw MissingPluginException('Synthetic unsupported desktop channel');
      },
    );
  });

  tearDown(() {
    binding.removeObserver(kit);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('walletconnect_pay'),
      null,
    );
  });

  test(
    'initializes signing with no desktop payment channel invocation',
    () async {
      await kit.init();
      await kit.init();
      expect(order, <String>['core', 'events', 'sign']);
      expect(paymentCalls, 0);
      expect(() => kit.pay, throwsUnsupportedError);
      verify(() => core.start()).called(1);
      verify(
        () => events.setQueryParams(<String, String>{
          'projectId': 'synthetic-project-id',
          'st': 'events_sdk',
          'sv': ReownCoreUtils.coreSdkVersion(packageVersion),
        }),
      ).called(1);
      verify(() => sign.init()).called(1);
    },
  );

  test(
    'concurrent initialization waits for the same signing operation',
    () async {
      final Completer<void> started = Completer<void>();
      final Completer<void> release = Completer<void>();
      when(() => sign.init()).thenAnswer((_) {
        started.complete();
        return release.future;
      });
      final Future<void> first = kit.init();
      await started.future;
      final Future<void> second = kit.init();
      expect(identical(first, second), isTrue);
      release.complete();
      await Future.wait(<Future<void>>[first, second]);
      expect(paymentCalls, 0);
      verify(() => sign.init()).called(1);
    },
  );

  test('failed signing initialization remains retryable', () async {
    int attempts = 0;
    when(() => sign.init()).thenAnswer((_) async {
      if (++attempts == 1) throw StateError('Synthetic signing failure');
    });
    await expectLater(kit.init(), throwsStateError);
    await kit.init();
    await kit.init();
    expect(attempts, 2);
    expect(paymentCalls, 0);
    verify(() => core.start()).called(2);
  });

  test(
    'core failure prevents events and signing from becoming ready',
    () async {
      when(() => core.start()).thenThrow(StateError('Synthetic core failure'));
      await expectLater(kit.init(), throwsStateError);
      verifyNever(() => events.sendStoredEvents());
      verifyNever(() => sign.init());
      expect(paymentCalls, 0);
    },
  );

  test(
    'DesktopSigningWalletKit wires SafeDisconnectReownSign and absorbs async '
    'WC_SESSION_DELETE sendRequest errors without leaking secrets or isolating '
    'shared futures across error zones',
    () async {
      final ReownCore desktopCore = createDesktopReownCore(
        projectId: 'test-project',
        memoryStore: true,
      );
      final DesktopSigningWalletKit desktopKit = DesktopSigningWalletKit(
        core: desktopCore,
        metadata: const PairingMetadata(
          name: 'Synthetic desktop wallet',
          description: 'Offline fixture',
          url: 'https://example.invalid',
        ),
      );
      expect(desktopKit.reOwnSign, isA<SafeDisconnectReownSign>());

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

      final _Core mockCore = _Core();
      final _RelayClient mockRelay = _RelayClient();
      final _Crypto mockCrypto = _Crypto();
      final _Expirer mockExpirer = _Expirer();
      final _HeartBeat mockHeartBeat = _HeartBeat();
      final _Verify mockVerify = _Verify();
      final _Pairing mockPairing = _Pairing();
      final _PairingStore mockPairingStore = _PairingStore();
      final _ProposalStore mockProposals = _ProposalStore();
      final _SessionStore mockSessions = _SessionStore();
      final _PendingRequestStore mockPendingRequests = _PendingRequestStore();
      final _AuthRequestStore mockAuthRequests = _AuthRequestStore();
      final _AuthKeyStore mockAuthKeys = _AuthKeyStore();
      final _StringStore mockPairingTopics = _StringStore();

      final Event<EventArgs> onRelayConnect = Event<EventArgs>();
      final Event<ExpirationEvent> onExpire = Event<ExpirationEvent>();
      final Event<PairingEvent> onPairingDelete = Event<PairingEvent>();
      final Event<PairingEvent> onPairingExpire = Event<PairingEvent>();
      final Event<EventArgs> onPulse = Event<EventArgs>();

      SessionData buildSession(String topic, String selfPublicKey) =>
          SessionData(
            topic: topic,
            pairingTopic: 'pairing-$topic',
            relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
            expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            acknowledged: true,
            controller: selfPublicKey,
            namespaces: const <String, Namespace>{},
            self: ConnectionMetadata(
              publicKey: selfPublicKey,
              metadata: const PairingMetadata(
                name: 'Wallet',
                description: 'Test',
                url: 'https://example.invalid',
              ),
            ),
            peer: const ConnectionMetadata(
              publicKey: 'peer-key',
              metadata: PairingMetadata(
                name: 'dApp',
                description: 'Test',
                url: 'https://example.invalid',
              ),
            ),
          );

      final Map<String, SessionData> storedSessions = <String, SessionData>{
        'sess-encode-fail': buildSession('sess-encode-fail', 'pk-encode'),
        'sess-publish-fail': buildSession('sess-publish-fail', 'pk-publish'),
        'sess-shared-fail': buildSession('sess-shared-fail', 'pk-shared'),
      };
      final Set<String> storedPairings = <String>{'pairing-fallback'};

      when(() => mockCore.logger).thenReturn(desktopCore.logger);
      when(() => mockCore.relayClient).thenReturn(mockRelay);
      when(() => mockCore.crypto).thenReturn(mockCrypto);
      when(() => mockCore.expirer).thenReturn(mockExpirer);
      when(() => mockCore.heartbeat).thenReturn(mockHeartBeat);
      when(() => mockCore.verify).thenReturn(mockVerify);
      when(() => mockCore.pairing).thenReturn(mockPairing);
      when(mockCore.confirmOnlineStateOrThrow).thenReturn(null);

      when(() => mockRelay.isConnected).thenReturn(false);
      when(() => mockRelay.onRelayClientConnect).thenReturn(onRelayConnect);
      when(
        () => mockRelay.unsubscribe(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
      when(() => mockExpirer.onExpire).thenReturn(onExpire);
      when(
        () => mockExpirer.checkAndExpire(any()),
      ).thenAnswer((_) async => false);
      when(() => mockHeartBeat.onPulse).thenReturn(onPulse);
      when(mockVerify.init).thenAnswer((_) async {});
      when(mockPairing.init).thenAnswer((_) async {});
      when(() => mockPairing.onPairingDelete).thenReturn(onPairingDelete);
      when(() => mockPairing.onPairingExpire).thenReturn(onPairingExpire);
      when(mockPairing.getStore).thenReturn(mockPairingStore);
      when(
        () => mockPairing.register(
          method: any(named: 'method'),
          function: any(named: 'function'),
          type: any(named: 'type'),
        ),
      ).thenReturn(null);
      when(
        () => mockPairing.isValidPairingTopic(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
      when(
        () => mockPairing.disconnect(topic: any(named: 'topic')),
      ).thenAnswer((_) async {});
      when(() => mockPairingStore.has(any())).thenAnswer(
        (Invocation i) => storedPairings.contains(i.positionalArguments[0]),
      );

      when(mockProposals.init).thenAnswer((_) async {});
      when(mockProposals.getAll).thenReturn(<ProposalData>[]);
      when(mockSessions.init).thenAnswer((_) async {});
      when(
        mockSessions.getAll,
      ).thenAnswer((_) => storedSessions.values.toList());
      when(() => mockSessions.has(any())).thenAnswer(
        (Invocation i) => storedSessions.containsKey(i.positionalArguments[0]),
      );
      when(
        () => mockSessions.get(any()),
      ).thenAnswer((Invocation i) => storedSessions[i.positionalArguments[0]]);
      when(() => mockSessions.delete(any())).thenAnswer((Invocation i) async {
        storedSessions.remove(i.positionalArguments[0] as String);
      });
      when(mockPendingRequests.init).thenAnswer((_) async {});
      when(mockAuthRequests.init).thenAnswer((_) async {});
      when(mockAuthKeys.init).thenAnswer((_) async {});
      when(mockPairingTopics.init).thenAnswer((_) async {});
      when(() => mockCrypto.deleteKeyPair(any())).thenAnswer((_) async {});
      when(() => mockCrypto.deleteSymKey(any())).thenAnswer((_) async {});

      when(
        () => mockPairing.sendRequest(
          'sess-encode-fail',
          MethodConstants.WC_SESSION_DELETE,
          any(),
        ),
      ).thenAnswer(
        (_) => Future<dynamic>.error(
          StateError('encode failed symKey=super-secret-session-encode'),
        ),
      );
      when(
        () => mockPairing.sendRequest(
          'sess-publish-fail',
          MethodConstants.WC_SESSION_DELETE,
          any(),
        ),
      ).thenAnswer(
        (_) => Future<dynamic>.error(
          const ReownCoreError(
            code: 9002,
            message: 'wc:secret@2?symKey=super-secret-session-publish',
          ),
        ),
      );

      Future<dynamic>? sharedReconnectFuture;
      when(
        () => mockPairing.sendRequest(
          'sess-shared-fail',
          MethodConstants.WC_SESSION_DELETE,
          any(),
        ),
      ).thenAnswer((_) {
        sharedReconnectFuture = Future<dynamic>.delayed(
          const Duration(milliseconds: 10),
          () => throw StateError('shared session reconnect failed'),
        );
        return sharedReconnectFuture!;
      });

      final SafeDisconnectReownSign safeSign = SafeDisconnectReownSign(
        core: mockCore,
        metadata: const PairingMetadata(
          name: 'Wallet',
          description: 'Test',
          url: 'https://example.invalid',
        ),
        proposals: mockProposals,
        sessions: mockSessions,
        pendingRequests: mockPendingRequests,
        sessionAuthRequests: mockAuthRequests,
        authKeys: mockAuthKeys,
        pairingTopics: mockPairingTopics,
      );

      // Uninitialized disconnectSession still throws NOT_INITIALIZED.
      await expectLater(
        safeSign.disconnectSession(
          topic: 'sess-encode-fail',
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
        ),
        throwsA(
          isA<ReownSignError>().having(
            (ReownSignError e) => e.code,
            'code',
            Errors.getInternalError(Errors.NOT_INITIALIZED).code,
          ),
        ),
      );

      await safeSign.init();

      final List<String> deletedSessionTopics = <String>[];
      safeSign.onSessionDelete.subscribe((SessionDelete? event) {
        if (event != null) {
          deletedSessionTopics.add(event.topic);
        }
      });

      final Completer<void> bodyDone = Completer<void>();
      runZonedGuarded<void>(
        () {
          unawaited(() async {
            try {
              final ReownSignError reason = Errors.getSdkError(
                Errors.USER_DISCONNECTED,
              ).toSignError();

              await safeSign.disconnectSession(
                topic: 'sess-encode-fail',
                reason: reason,
              );
              await safeSign.disconnectSession(
                topic: 'sess-publish-fail',
                reason: reason,
              );

              // Shared future returned by sendRequest must stay in the
              // caller's error zone so another caller awaiting it receives the
              // error cleanly instead of hanging across error zones.
              await safeSign.disconnectSession(
                topic: 'sess-shared-fail',
                reason: reason,
              );
              expect(sharedReconnectFuture, isNotNull);
              await expectLater(
                sharedReconnectFuture!.timeout(const Duration(seconds: 1)),
                throwsA(isA<StateError>()),
              );

              // Pairing fallback delegates to core.pairing.disconnect.
              await safeSign.disconnectSession(
                topic: 'pairing-fallback',
                reason: reason,
              );

              // Unknown topic is caught and logged as ReownSignError, matching
              // upstream SignEngine.disconnectSession().
              await safeSign.disconnectSession(
                topic: 'missing-topic',
                reason: reason,
              );

              await Future<void>.delayed(const Duration(milliseconds: 20));
              bodyDone.complete();
            } on Object catch (e, s) {
              bodyDone.completeError(e, s);
            }
          }());
        },
        (Object error, StackTrace _) {
          uncaughtErrors.add(error);
        },
      );

      await bodyDone.future;

      expect(uncaughtErrors, isEmpty);
      expect(storedSessions, isEmpty);
      expect(
        deletedSessionTopics,
        equals(<String>[
          'sess-encode-fail',
          'sess-publish-fail',
          'sess-shared-fail',
        ]),
      );
      verify(() => mockRelay.unsubscribe(topic: 'sess-encode-fail')).called(1);
      verify(() => mockCrypto.deleteKeyPair('pk-encode')).called(1);
      verify(() => mockCrypto.deleteSymKey('sess-encode-fail')).called(1);
      verify(() => mockPairing.disconnect(topic: 'pairing-fallback')).called(1);
      expect(
        logs.any(
          (LogRecord record) =>
              record.message.contains('wc_sessionDelete') &&
              record.message.contains('ReownCoreError(code=9002)'),
        ),
        isTrue,
      );
      expect(
        logs.any(
          (LogRecord record) =>
              record.message.contains('super-secret-session-encode') ||
              record.message.contains('super-secret-session-publish'),
        ),
        isFalse,
      );
    },
  );

  test(
    'SafeDisconnectPairing guards async ReownSign._onPairingDelete listener '
    'errors on onPairingDelete and onPairingExpire without leaking secrets',
    () async {
      final ReownCore desktopCore = createDesktopReownCore(
        projectId: 'test-project',
        memoryStore: true,
      );
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

      final _Core mockCore = _Core();
      final _RelayClient mockRelay = _RelayClient();
      final _Crypto mockCrypto = _Crypto();
      final _Expirer mockExpirer = _Expirer();
      final _HeartBeat mockHeartBeat = _HeartBeat();
      final _Verify mockVerify = _Verify();
      final _Events mockEvents = _Events();
      final _PairingStore mockPairingStore = _PairingStore();
      final _JsonRpcHistory mockHistory = _JsonRpcHistory();
      final _ReceiverKeyStore mockReceiverKeys = _ReceiverKeyStore();
      final _ProposalStore mockProposals = _ProposalStore();
      final _SessionStore mockSessions = _SessionStore();
      final _PendingRequestStore mockPendingRequests = _PendingRequestStore();
      final _AuthRequestStore mockAuthRequests = _AuthRequestStore();
      final _AuthKeyStore mockAuthKeys = _AuthKeyStore();
      final _StringStore mockPairingTopics = _StringStore();

      final Event<EventArgs> onRelayConnect = Event<EventArgs>();
      final Event<MessageEvent> onRelayMessage = Event<MessageEvent>();
      final Event<MessageEvent> onLinkModeMessage = Event<MessageEvent>();
      final Event<ExpirationEvent> onExpire = Event<ExpirationEvent>();
      final Event<EventArgs> onPulse = Event<EventArgs>();

      when(() => mockCore.logger).thenReturn(desktopCore.logger);
      when(() => mockCore.relayClient).thenReturn(mockRelay);
      when(() => mockCore.crypto).thenReturn(mockCrypto);
      when(() => mockCore.expirer).thenReturn(mockExpirer);
      when(() => mockCore.heartbeat).thenReturn(mockHeartBeat);
      when(() => mockCore.verify).thenReturn(mockVerify);
      when(() => mockCore.events).thenReturn(mockEvents);
      when(() => mockRelay.isConnected).thenReturn(false);
      when(() => mockRelay.onRelayClientConnect).thenReturn(onRelayConnect);
      when(() => mockRelay.onRelayClientMessage).thenReturn(onRelayMessage);
      when(() => mockRelay.onLinkModeMessage).thenReturn(onLinkModeMessage);
      when(() => mockExpirer.onExpire).thenReturn(onExpire);
      when(mockExpirer.init).thenAnswer((_) async {});
      when(() => mockHeartBeat.onPulse).thenReturn(onPulse);
      when(mockVerify.init).thenAnswer((_) async {});
      when(mockPairingStore.init).thenAnswer((_) async {});
      when(mockPairingStore.getAll).thenReturn(<PairingInfo>[]);
      when(mockHistory.init).thenAnswer((_) async {});
      when(mockHistory.getAll).thenReturn(<JsonRpcRecord>[]);
      when(mockReceiverKeys.init).thenAnswer((_) async {});
      when(mockReceiverKeys.getAll).thenReturn(<ReceiverPublicKey>[]);

      final SafeDisconnectPairing safePairing = SafeDisconnectPairing(
        core: mockCore,
        pairings: mockPairingStore,
        history: mockHistory,
        topicToReceiverPublicKey: mockReceiverKeys,
      );
      when(() => mockCore.pairing).thenReturn(safePairing);

      final SessionData orphanSession = SessionData(
        topic: 'child-sess',
        pairingTopic: 'p-deleted',
        relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
        expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        acknowledged: true,
        controller: 'pk',
        namespaces: const <String, Namespace>{},
        self: const ConnectionMetadata(
          publicKey: 'pk',
          metadata: PairingMetadata(
            name: 'Wallet',
            description: 'Test',
            url: 'https://example.invalid',
          ),
        ),
        peer: const ConnectionMetadata(
          publicKey: 'peer-pk',
          metadata: PairingMetadata(
            name: 'dApp',
            description: 'Test',
            url: 'https://example.invalid',
          ),
        ),
      );

      when(mockProposals.init).thenAnswer((_) async {});
      when(mockProposals.getAll).thenReturn(<ProposalData>[]);
      when(mockSessions.init).thenAnswer((_) async {});
      when(mockSessions.getAll).thenReturn(<SessionData>[orphanSession]);
      when(() => mockSessions.get('child-sess')).thenReturn(orphanSession);
      when(mockPendingRequests.init).thenAnswer((_) async {});
      when(mockAuthRequests.init).thenAnswer((_) async {});
      when(mockAuthKeys.init).thenAnswer((_) async {});
      when(mockPairingTopics.init).thenAnswer((_) async {});
      when(() => mockRelay.unsubscribe(topic: 'child-sess')).thenAnswer(
        (_) => Future<void>.error(
          StateError('unsubscribe boom symKey=super-secret-listener'),
        ),
      );

      final SafeDisconnectReownSign safeSign = SafeDisconnectReownSign(
        core: mockCore,
        metadata: const PairingMetadata(
          name: 'Wallet',
          description: 'Test',
          url: 'https://example.invalid',
        ),
        proposals: mockProposals,
        sessions: mockSessions,
        pendingRequests: mockPendingRequests,
        sessionAuthRequests: mockAuthRequests,
        authKeys: mockAuthKeys,
        pairingTopics: mockPairingTopics,
      );
      await safeSign.init();

      final List<String> syncObserved = <String>[];
      void syncListener(PairingEvent? event) {
        if (event?.topic != null) {
          syncObserved.add(event!.topic!);
        }
      }

      safePairing.onPairingDelete.subscribe(syncListener);

      final Completer<void> bodyDone = Completer<void>();
      runZonedGuarded<void>(
        () {
          unawaited(() async {
            try {
              safePairing.onPairingDelete.broadcast(
                PairingEvent(topic: 'p-deleted'),
              );
              safePairing.onPairingExpire.broadcast(
                PairingEvent(topic: 'p-deleted'),
              );
              await Future<void>.delayed(const Duration(milliseconds: 20));

              expect(
                safePairing.onPairingDelete.unsubscribe(syncListener),
                isTrue,
              );
              safePairing.onPairingDelete.broadcast(
                PairingEvent(topic: 'after-unsubscribe'),
              );
              await Future<void>.delayed(const Duration(milliseconds: 10));
              bodyDone.complete();
            } on Object catch (e, s) {
              bodyDone.completeError(e, s);
            }
          }());
        },
        (Object error, StackTrace _) {
          uncaughtErrors.add(error);
        },
      );

      await bodyDone.future;

      expect(uncaughtErrors, isEmpty);
      expect(syncObserved, equals(<String>['p-deleted']));
      expect(
        logs.any(
          (LogRecord record) =>
              record.message.contains('onPairingDelete') &&
              record.message.contains('StateError'),
        ),
        isTrue,
      );
      expect(
        logs.any(
          (LogRecord record) =>
              record.message.contains('onPairingExpire') &&
              record.message.contains('StateError'),
        ),
        isTrue,
      );
      expect(
        logs.any(
          (LogRecord record) =>
              record.message.contains('super-secret-listener'),
        ),
        isFalse,
      );
    },
  );
}
