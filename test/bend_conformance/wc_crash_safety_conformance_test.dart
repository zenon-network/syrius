@Tags(<String>['bend'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_core/crypto/i_crypto.dart';
import 'package:reown_core/pairing/i_expirer.dart';
import 'package:reown_core/pairing/i_pairing.dart';
import 'package:reown_core/relay_client/i_message_tracker.dart';
import 'package:reown_core/relay_client/i_relay_client.dart';
import 'package:reown_core/store/generic_store.dart';
import 'package:reown_core/store/i_generic_store.dart';
import 'package:reown_core/store/i_store.dart';
import 'package:reown_core/store/shared_prefs_store.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/services/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/sticky_fallback_secure_store.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'wc_crash_safety';

class _MemoryStore implements IStore<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _data =
      <String, Map<String, dynamic>>{};
  bool Function(String key)? shouldFailOnSet;
  bool Function(String key)? shouldFailOnDelete;

  @override
  Map<String, Map<String, dynamic>> get map => _data;

  @override
  List<String> get keys => _data.keys.toList();

  @override
  List<Map<String, dynamic>> get values => _data.values.toList();

  @override
  String get storagePrefix => ReownConstants.CORE_STORAGE_PREFIX;

  String _addPrefix(String key) => '$storagePrefix$key';

  @override
  Future<void> init() async {}

  @override
  Future<void> set(String key, Map<String, dynamic> value) async {
    if (shouldFailOnSet?.call(key) ?? false) {
      throw StateError('fallback set failed for $key');
    }
    _data[_addPrefix(key)] = Map<String, dynamic>.from(value);
  }

  @override
  Map<String, dynamic>? get(String key) => _data[_addPrefix(key)];

  @override
  bool has(String key) => _data.containsKey(_addPrefix(key));

  @override
  List<dynamic> getAll() => values;

  @override
  Future<void> update(String key, Map<String, dynamic> value) async {
    _data[_addPrefix(key)] = Map<String, dynamic>.from(value);
  }

  @override
  Future<void> delete(String key) async {
    if (shouldFailOnDelete?.call(key) ?? false) {
      throw StateError('fallback delete failed for $key');
    }
    _data.remove(_addPrefix(key));
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage({
    this.failWrites = false,
    this.failReads = false,
    Map<String, String>? initialData,
  }) : data = initialData ?? <String, String>{};

  final Map<String, String> data;
  bool failWrites;
  bool failReads;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrites) {
      throw Exception('keychain write denied');
    }
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failReads) {
      throw Exception('keychain read denied');
    }
    return data[key];
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failReads) {
      throw Exception('keychain read denied');
    }
    return Map<String, String>.from(data);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrites) {
      throw Exception('keychain delete denied');
    }
    data.remove(key);
  }
}

class _MockWalletKit extends Mock implements ReownWalletKit {}

class _MockCore extends Mock implements IReownCore {}

class _MockRelayClient extends Mock implements IRelayClient {}

class _MockPairing extends Mock implements IPairing {}

class _MockPairingStore extends Mock implements IPairingStore {}

class _MockSessionStore extends Mock implements ISessions {}

class _MockCrypto extends Mock implements ICrypto {}

class _MockKeyChainStore extends Mock implements IGenericStore<String> {}

class _MockExpirer extends Mock implements IExpirer {}

class _MockMessageTracker extends Mock implements IMessageTracker {}

class _MockNoMService extends Mock implements NoMService {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

class _TestConfirmingRelayClient extends ConfirmingRelayClient {
  _TestConfirmingRelayClient({
    required super.core,
    required super.messageTracker,
    required super.topicMap,
    required this.onSendUnsubscribeRpc,
  });

  bool connected = true;
  final Future<dynamic> Function({
    required String method,
    required Map<String, dynamic> parameters,
    required int id,
  })
  onSendUnsubscribeRpc;

  @override
  bool get isConnected => connected;

  @override
  Future<void> init() async {
    await messageTracker.init();
    await topicMap.init();
    await super.init();
  }

  @override
  Future<void> connect({String? relayUrl}) async {}

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  Future<dynamic> sendUnsubscribeRpc({
    required String method,
    required Map<String, dynamic> parameters,
    required int id,
  }) {
    return onSendUnsubscribeRpc(method: method, parameters: parameters, id: id);
  }
}

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

String _classifyStoreMode(
  StickyFallbackSecureStore store,
  _MemoryStore fallback,
) {
  if (!store.isUsingFallback) {
    return 'secure';
  }
  final Map<String, dynamic>? flag = fallback.get(
    StickyFallbackSecureStore.fallbackFlagKey,
  );
  if (flag == null) {
    return 'transient_fallback';
  }
  final bool authoritative = (flag['authoritative'] as bool?) ?? true;
  return authoritative ? 'authoritative_fallback' : 'transient_fallback';
}

Future<String> _runStoreBootMode({
  required String marker,
  required bool clearedAll,
  required bool hasDeleted,
  required bool hasReplaced,
  required bool hasTransientKeys,
  required bool osReadOk,
  required bool osReconcileWriteOk,
  required bool fallbackWriteOk,
  required bool keychainHadEntries,
}) async {
  final _MemoryStore fallback = _MemoryStore();
  if (marker == 'authoritative') {
    await fallback.set(
      StickyFallbackSecureStore.fallbackFlagKey,
      <String, dynamic>{
        'enabled': true,
        'authoritative': true,
        'keys': <String>['k1'],
      },
    );
    await fallback.set('k1', <String, dynamic>{'v': 1});
  } else if (marker == 'legacy') {
    await fallback.set(
      StickyFallbackSecureStore.fallbackFlagKey,
      <String, dynamic>{'enabled': true},
    );
  } else if (marker == 'transient') {
    await fallback.set(
      StickyFallbackSecureStore.fallbackFlagKey,
      <String, dynamic>{
        'enabled': true,
        'authoritative': false,
        'keys': hasTransientKeys ? <String>['k_tr'] : <String>[],
        if (hasDeleted) 'deletedKeys': <String>['k_del'],
        if (hasReplaced) 'replacedKeys': <String>['k_tr'],
        if (clearedAll) 'clearedAll': true,
      },
    );
    if (hasTransientKeys) {
      await fallback.set('k_tr', <String, dynamic>{'sub_a': 1});
    }
  }

  fallback.shouldFailOnSet = (String _) => !fallbackWriteOk;

  final Map<String, String> osData = <String, String>{};
  if (keychainHadEntries) {
    osData['${ReownConstants.CORE_STORAGE_PREFIX}k_os'] = jsonEncode(
      <String, dynamic>{'sub_a': 9},
    );
  }
  if (hasDeleted) {
    osData['${ReownConstants.CORE_STORAGE_PREFIX}k_del'] = jsonEncode(
      <String, dynamic>{'sub_a': 5},
    );
  }

  final _FakeSecureStorage keychain = _FakeSecureStorage(
    failReads: !osReadOk,
    failWrites: !osReconcileWriteOk,
    initialData: osData,
  );
  final StickyFallbackSecureStore store = StickyFallbackSecureStore(
    fallbackStorage: fallback,
    secureStorage: keychain,
  );

  try {
    await store.init();
  } on Object {
    // Migration write failure during reconciliation leaves transient fallback
    // mode intact (not yet authoritative).
    return 'transient_fallback';
  }
  return _classifyStoreMode(store, fallback);
}

Future<String> _runStoreAuthoritativeStickyStep({
  required String op,
  required bool osOk,
}) async {
  final _MemoryStore fallback = _MemoryStore();
  final _FakeSecureStorage failingKeychain = _FakeSecureStorage(
    failWrites: true,
  );
  final StickyFallbackSecureStore store = StickyFallbackSecureStore(
    fallbackStorage: fallback,
    secureStorage: failingKeychain,
  );
  await store.init();
  await store.set('owned_k', <String, dynamic>{'a': 1});

  // Keychain later becomes healthy (or stays unhealthy).
  failingKeychain
    ..failReads = !osOk
    ..failWrites = !osOk;

  switch (op) {
    case 'read':
      store.get('owned_k');
      return _classifyStoreMode(store, fallback);
    case 'write':
      await store.set('owned_k2', <String, dynamic>{'a': 2});
      return _classifyStoreMode(store, fallback);
    case 'delete':
      await store.delete('owned_k');
      return _classifyStoreMode(store, fallback);
    case 'delete_all':
      await store.deleteAll();
      return _classifyStoreMode(store, fallback);
    case 'restart':
      final StickyFallbackSecureStore relaunched = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: _FakeSecureStorage(
          failReads: !osOk,
          failWrites: !osOk,
        ),
      );
      await relaunched.init();
      return _classifyStoreMode(relaunched, fallback);
    default:
      fail('Unknown StoreOp "$op"');
  }
}

Future<Map<String, Object>> _runStoreIsolationAndDeleteAll({
  required String keyKind,
  required bool ownedPresent,
}) async {
  final _MemoryStore fallback = _MemoryStore();
  await fallback.set('foreign_core_k', <String, dynamic>{'ext': true});

  final StickyFallbackSecureStore store = StickyFallbackSecureStore(
    fallbackStorage: fallback,
    secureStorage: _FakeSecureStorage(failWrites: true),
  );
  await store.init();
  await store.set('bootstrap_k', <String, dynamic>{'init': 1});
  if (ownedPresent) {
    await store.set('owned_k', <String, dynamic>{'owned': 1});
  }

  final String targetKey = switch (keyKind) {
    'fallback_flag' => StickyFallbackSecureStore.fallbackFlagKey,
    'foreign' => 'foreign_core_k',
    'owned' => 'owned_k',
    _ => fail('Unknown key_kind "$keyKind"'),
  };
  final bool existedBefore = fallback.has(targetKey);
  await store.delete(targetKey);
  final bool deletedByDelete = existedBefore && !fallback.has(targetKey);

  await store.deleteAll();
  final bool flagPreserved = fallback.has(
    StickyFallbackSecureStore.fallbackFlagKey,
  );
  final bool foreignPreserved = fallback.has('foreign_core_k');

  return <String, Object>{
    'deleted': deletedByDelete,
    'flag_preserved': flagPreserved,
    'foreign_preserved': foreignPreserved,
  };
}

Future<Map<String, Object?>> _runStoreReconcileKeyView({
  required bool clearedAll,
  required bool inDeletedKeys,
  required bool inReplacedKeys,
  required bool osPresent,
  required int? osSubA,
  required int? osSubB,
  required bool trPresent,
  required int? trSubA,
  required int? trSubB,
}) async {
  final _MemoryStore fallback = _MemoryStore();
  final Map<String, String> osData = <String, String>{};
  const String prefix = ReownConstants.CORE_STORAGE_PREFIX;

  // Ensure reconciliation runs when OS keychain is otherwise empty and flags
  // are false (otherwise StickyFallbackSecureStore stays in transient mode).
  if (!osPresent && !clearedAll && !inDeletedKeys && !inReplacedKeys) {
    osData['${prefix}sentinel_os'] = jsonEncode(<String, dynamic>{'s': 1});
  }
  if (osPresent) {
    final Map<String, dynamic> osVal = <String, dynamic>{
      'sub_a': ?osSubA,
      'sub_b': ?osSubB,
    };
    osData['${prefix}wc_key'] = jsonEncode(osVal);
  }

  final List<String> transientKeys = <String>[if (trPresent) 'wc_key'];
  if (trPresent) {
    await fallback.set('wc_key', <String, dynamic>{
      'sub_a': ?trSubA,
      'sub_b': ?trSubB,
    });
  }
  await fallback.set(
    StickyFallbackSecureStore.fallbackFlagKey,
    <String, dynamic>{
      'enabled': true,
      'authoritative': false,
      'keys': transientKeys,
      if (inDeletedKeys) 'deletedKeys': <String>['wc_key'],
      if (inReplacedKeys) 'replacedKeys': <String>['wc_key'],
      if (clearedAll) 'clearedAll': true,
    },
  );

  final StickyFallbackSecureStore store = StickyFallbackSecureStore(
    fallbackStorage: fallback,
    secureStorage: _FakeSecureStorage(initialData: osData),
  );
  await store.init();

  final Map<String, dynamic>? reconciled = store.get('wc_key');
  if (reconciled == null) {
    return <String, Object?>{'present': false, 'sub_a': null, 'sub_b': null};
  }
  return <String, Object?>{
    'present': true,
    'sub_a': reconciled['sub_a'] as int?,
    'sub_b': reconciled['sub_b'] as int?,
  };
}

Future<Map<String, Object>> _runStoreMigrationCommitOrder({
  required bool entriesWriteOk,
  required bool markerWriteOk,
}) async {
  final _MemoryStore fallback = _MemoryStore();
  final _FakeSecureStorage keychain = _FakeSecureStorage();
  final StickyFallbackSecureStore store = StickyFallbackSecureStore(
    fallbackStorage: fallback,
    secureStorage: keychain,
  );
  await store.init();
  await store.set('existing_k', <String, dynamic>{'x': 1});

  keychain.failWrites = true;
  fallback.shouldFailOnSet = (String key) {
    if (key == StickyFallbackSecureStore.fallbackFlagKey) {
      return !markerWriteOk;
    }
    return !entriesWriteOk;
  };

  try {
    await store.set('new_k', <String, dynamic>{'y': 2});
  } on Object {
    // Expected when entriesWriteOk or markerWriteOk is false.
  }

  return <String, Object>{
    'marker_persisted': fallback.has(StickyFallbackSecureStore.fallbackFlagKey),
    'next_mode': _classifyStoreMode(store, fallback),
  };
}

Future<Map<String, Object>> _runStoreReconciliationCleanupOrder({
  required bool markerDeleteOk,
  required bool copiesDeleteOk,
}) async {
  final _MemoryStore fallback = _MemoryStore();
  await fallback.set('post_reset_k', <String, dynamic>{'v': 1});
  await fallback.set(
    StickyFallbackSecureStore.fallbackFlagKey,
    <String, dynamic>{
      'enabled': true,
      'authoritative': false,
      'keys': <String>['post_reset_k'],
      'clearedAll': true,
    },
  );
  fallback.shouldFailOnDelete = (String key) {
    if (key == StickyFallbackSecureStore.fallbackFlagKey) {
      return !markerDeleteOk;
    }
    return !copiesDeleteOk;
  };

  final StickyFallbackSecureStore store = StickyFallbackSecureStore(
    fallbackStorage: fallback,
    secureStorage: _FakeSecureStorage(),
  );
  try {
    await store.init();
  } on Object {
    // Expected when marker delete fails.
  }

  return <String, Object>{
    'marker_deleted': !fallback.has(StickyFallbackSecureStore.fallbackFlagKey),
    'copies_deleted': !fallback.has('post_reset_k'),
  };
}

Future<(_TestConfirmingRelayClient, GenericStore<String>)>
_buildConfirmingRelay({
  required Future<dynamic> Function({
    required String method,
    required Map<String, dynamic> parameters,
    required int id,
  })
  onRpc,
}) async {
  final ReownCore desktopCore = createDesktopReownCore(
    projectId: 'test-project-id',
    memoryStore: true,
  );
  await desktopCore.storage.init();
  await desktopCore.secureStorage.init();
  await desktopCore.crypto.init();

  final _MockCore mockCore = _MockCore();
  when(() => mockCore.logger).thenReturn(desktopCore.logger);
  when(() => mockCore.heartbeat).thenReturn(desktopCore.heartbeat);
  when(() => mockCore.crypto).thenReturn(desktopCore.crypto);

  final SharedPrefsStores memStorage = SharedPrefsStores(memoryStore: true);
  await memStorage.init();
  final GenericStore<String> topicMap = GenericStore<String>(
    storage: memStorage,
    context: StoreVersions.CONTEXT_TOPIC_MAP,
    version: StoreVersions.VERSION_TOPIC_MAP,
    fromJson: (dynamic value) => value as String,
  );
  final _MockMessageTracker tracker = _MockMessageTracker();
  when(tracker.init).thenAnswer((_) async {});
  when(() => tracker.delete(any())).thenAnswer((_) async {});

  final _TestConfirmingRelayClient relay = _TestConfirmingRelayClient(
    core: mockCore,
    messageTracker: tracker,
    topicMap: topicMap,
    onSendUnsubscribeRpc: onRpc,
  );
  await relay.init();
  return (relay, topicMap);
}

Future<Map<String, Object>> _runRelayUnsubscribeFencing(String scenario) async {
  Future<dynamic> Function({
    required String method,
    required Map<String, dynamic> parameters,
    required int id,
  })
  handler =
      ({
        required String method,
        required Map<String, dynamic> parameters,
        required int id,
      }) async => true;

  final (_TestConfirmingRelayClient relay, GenericStore<String> topicMap) =
      await _buildConfirmingRelay(
        onRpc:
            ({
              required String method,
              required Map<String, dynamic> parameters,
              required int id,
            }) => handler(method: method, parameters: parameters, id: id),
      );

  switch (scenario) {
    case 'offline_fail':
      await topicMap.set('t1', 'sub-1');
      relay.connected = false;
      await relay.unsubscribeWithConfirmation(topic: 't1');
      return <String, Object>{
        'topic_map_kept': topicMap.has('t1'),
        'preserved_id_present': relay.preservedUnsubscribeId('t1') == 'sub-1',
        'unconfirmed': relay.hasUnconfirmedUnsubscribe('t1'),
      };

    case 'rpc_confirmed':
      await topicMap.set('t1', 'sub-1');
      relay.connected = true;
      await relay.unsubscribeWithConfirmation(topic: 't1');
      return <String, Object>{
        'topic_map_kept': topicMap.has('t1'),
        'preserved_id_present': relay.preservedUnsubscribeId('t1') != null,
        'unconfirmed': relay.hasUnconfirmedUnsubscribe('t1'),
      };

    case 'stale_sub_fence':
      await topicMap.set('t1', 'sub-old');
      final Completer<void> rpcStarted = Completer<void>();
      final Completer<void> releaseRpc = Completer<void>();
      handler =
          ({
            required String method,
            required Map<String, dynamic> parameters,
            required int id,
          }) async {
            if (!rpcStarted.isCompleted) rpcStarted.complete();
            await releaseRpc.future;
            throw StateError('stale unsub failed');
          };
      final Future<bool> pendingUnsub = relay.unsubscribeWithConfirmation(
        topic: 't1',
      );
      await rpcStarted.future;
      final String replacementId = await relay.subscribe(
        options: const SubscribeOptions(topic: 't1', skipSubscribe: true),
      );
      releaseRpc.complete();
      await pendingUnsub;
      return <String, Object>{
        'topic_map_kept': topicMap.get('t1') == replacementId,
        'preserved_id_present': relay.preservedUnsubscribeId('t1') != null,
        'unconfirmed': relay.hasUnconfirmedUnsubscribe('t1'),
      };

    case 'concurrent_unsub_fence':
      await topicMap.set('t1', 'sub-conc');
      final Completer<void> firstStarted = Completer<void>();
      final Completer<void> releaseFirst = Completer<void>();
      int calls = 0;
      handler =
          ({
            required String method,
            required Map<String, dynamic> parameters,
            required int id,
          }) async {
            calls += 1;
            if (calls == 1) {
              if (!firstStarted.isCompleted) firstStarted.complete();
              await releaseFirst.future;
              throw StateError('first unsub timed out');
            }
            return true;
          };
      final Future<bool> firstUnsub = relay.unsubscribeWithConfirmation(
        topic: 't1',
      );
      await firstStarted.future;
      final bool secondOk = await relay.unsubscribeWithConfirmation(
        topic: 't1',
      );
      releaseFirst.complete();
      await firstUnsub;
      return <String, Object>{
        'topic_map_kept': topicMap.has('t1'),
        'preserved_id_present':
            !secondOk || relay.preservedUnsubscribeId('t1') != null,
        'unconfirmed': relay.hasUnconfirmedUnsubscribe('t1'),
      };

    default:
      fail('Unknown relay scenario "$scenario"');
  }
}

Future<bool> _runRelayRestorePreservedId({
  required bool hasActiveSub,
  required bool hasExistingPreserved,
  required bool hasTopicMapEntry,
  required bool persistedIdNonEmpty,
}) async {
  final (_TestConfirmingRelayClient relay, GenericStore<String> topicMap) =
      await _buildConfirmingRelay(
        onRpc:
            ({
              required String method,
              required Map<String, dynamic> parameters,
              required int id,
            }) async => true,
      );

  if (hasActiveSub) {
    await relay.subscribe(
      options: const SubscribeOptions(topic: 't1', skipSubscribe: true),
    );
  }
  if (hasExistingPreserved) {
    await topicMap.set('t1', 'sub-mem');
    relay.connected = false;
    await relay.unsubscribeWithConfirmation(topic: 't1');
  }
  if (hasTopicMapEntry) {
    await topicMap.set('t1', 'sub-map');
  }

  relay.restorePreservedUnsubscribeId(
    topic: 't1',
    subscriptionId: persistedIdNonEmpty ? 'sub-persisted' : '',
  );
  return relay.preservedUnsubscribeId('t1') == 'sub-persisted';
}

class _ServiceHarness {
  _ServiceHarness._({
    required this.service,
    required this.walletKit,
    required this.coreStorage,
    required this.sessionStore,
    required this.pairingStore,
    required this.relayClient,
    required this.nomService,
    required this.activeSessions,
    required this.pendingRequests,
    required this.onSessionRequest,
    required this.onSessionConnect,
    required this.onRelayConnect,
  });

  final Web3WalletService service;
  final _MockWalletKit walletKit;
  final _MemoryStore coreStorage;
  final _MockSessionStore sessionStore;
  final _MockPairingStore pairingStore;
  final _MockRelayClient relayClient;
  final _MockNoMService nomService;
  final Map<String, SessionData> activeSessions;
  final Map<String, SessionRequest> pendingRequests;
  final Event<SessionRequestEvent> onSessionRequest;
  final Event<SessionConnect> onSessionConnect;
  final Event<EventArgs> onRelayConnect;
}

_ServiceHarness _createServiceHarness() {
  final _MockWalletKit walletKit = _MockWalletKit();
  final _MockCore core = _MockCore();
  final _MockRelayClient relayClient = _MockRelayClient();
  final _MockPairing pairing = _MockPairing();
  final _MockPairingStore pairingStore = _MockPairingStore();
  final _MockSessionStore sessionStore = _MockSessionStore();
  final _MemoryStore coreStorage = _MemoryStore();
  final _MockCrypto crypto = _MockCrypto();
  final _MockKeyChainStore keyChainStore = _MockKeyChainStore();
  final _MockExpirer expirer = _MockExpirer();
  final _MockNoMService nomService = _MockNoMService();

  final Event<SessionRequestEvent> onSessionRequest =
      Event<SessionRequestEvent>();
  final Event<SessionProposalEvent> onSessionProposal =
      Event<SessionProposalEvent>();
  final Event<SessionConnect> onSessionConnect = Event<SessionConnect>();
  final Event<SessionProposalErrorEvent> onSessionProposalError =
      Event<SessionProposalErrorEvent>();
  final Event<SessionDelete> onSessionDelete = Event<SessionDelete>();
  final Event<StoreSyncEvent> onPairingsSync = Event<StoreSyncEvent>();
  final Event<StoreSyncEvent> onSessionsSync = Event<StoreSyncEvent>();
  final Event<EventArgs> onRelayConnect = Event<EventArgs>();
  final Event<EventArgs> onRelayDisconnect = Event<EventArgs>();
  final Event<ErrorEvent> onRelayError = Event<ErrorEvent>();
  final Event<PairingEvent> onPairingCreate = Event<PairingEvent>();
  final Event<PairingActivateEvent> onPairingActivate =
      Event<PairingActivateEvent>();
  final Event<PairingEvent> onPairingPing = Event<PairingEvent>();
  final Event<PairingInvalidEvent> onPairingInvalid =
      Event<PairingInvalidEvent>();
  final Event<PairingEvent> onPairingDelete = Event<PairingEvent>();

  final Map<String, SessionData> activeSessions = <String, SessionData>{};
  final Map<String, SessionRequest> pendingRequests =
      <String, SessionRequest>{};

  when(() => walletKit.core).thenReturn(core);
  when(() => core.relayClient).thenReturn(relayClient);
  when(() => core.pairing).thenReturn(pairing);
  when(() => core.storage).thenReturn(coreStorage);
  when(() => core.crypto).thenReturn(crypto);
  when(() => core.expirer).thenReturn(expirer);
  when(() => crypto.keyChain).thenReturn(keyChainStore);
  when(() => crypto.deleteKeyPair(any())).thenAnswer((_) async {});
  when(() => crypto.deleteSymKey(any())).thenAnswer((_) async {});
  when(keyChainStore.persist).thenAnswer((_) async {});
  when(() => expirer.delete(any())).thenAnswer((_) async {});
  when(expirer.persist).thenAnswer((_) async {});
  when(() => relayClient.isConnected).thenReturn(false);
  when(
    () => relayClient.unsubscribe(topic: any(named: 'topic')),
  ).thenAnswer((_) async {});
  when(relayClient.disconnect).thenAnswer((_) async {});
  when(relayClient.connect).thenAnswer((_) async {});
  when(() => pairingStore.delete(any())).thenAnswer((_) async {});
  when(pairingStore.persist).thenAnswer((_) async {});
  when(() => sessionStore.delete(any())).thenAnswer((_) async {});
  when(sessionStore.persist).thenAnswer((_) async {});
  when(() => walletKit.pairings).thenReturn(pairingStore);
  when(() => walletKit.sessions).thenReturn(sessionStore);

  when(() => relayClient.onRelayClientConnect).thenReturn(onRelayConnect);
  when(() => relayClient.onRelayClientDisconnect).thenReturn(onRelayDisconnect);
  when(() => relayClient.onRelayClientError).thenReturn(onRelayError);

  when(() => pairing.onPairingCreate).thenReturn(onPairingCreate);
  when(() => pairing.onPairingActivate).thenReturn(onPairingActivate);
  when(() => pairing.onPairingPing).thenReturn(onPairingPing);
  when(() => pairing.onPairingInvalid).thenReturn(onPairingInvalid);
  when(() => pairing.onPairingDelete).thenReturn(onPairingDelete);

  when(() => pairingStore.onSync).thenReturn(onPairingsSync);
  when(() => sessionStore.onSync).thenReturn(onSessionsSync);
  when(pairingStore.getAll).thenReturn(<PairingInfo>[]);
  when(sessionStore.getAll).thenAnswer((_) => activeSessions.values.toList());

  when(() => walletKit.onSessionProposal).thenReturn(onSessionProposal);
  when(() => walletKit.onSessionConnect).thenReturn(onSessionConnect);
  when(() => walletKit.onSessionRequest).thenReturn(onSessionRequest);
  when(
    () => walletKit.onSessionProposalError,
  ).thenReturn(onSessionProposalError);
  when(() => walletKit.onSessionDelete).thenReturn(onSessionDelete);

  when(walletKit.init).thenAnswer((_) async {});
  when(
    walletKit.getPendingSessionProposals,
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
    walletKit.getActiveSessions,
  ).thenAnswer((_) => Map<String, SessionData>.from(activeSessions));
  when(
    walletKit.getPendingSessionRequests,
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

  final Web3WalletService service = Web3WalletService(
    walletKit: walletKit,
    chainResolver: (String _) => nomService,
    inFlightPairWaitTimeout: const Duration(milliseconds: 50),
  );
  return _ServiceHarness._(
    service: service,
    walletKit: walletKit,
    coreStorage: coreStorage,
    sessionStore: sessionStore,
    pairingStore: pairingStore,
    relayClient: relayClient,
    nomService: nomService,
    activeSessions: activeSessions,
    pendingRequests: pendingRequests,
    onSessionRequest: onSessionRequest,
    onSessionConnect: onSessionConnect,
    onRelayConnect: onRelayConnect,
  );
}

Future<bool> _runServiceAdmissionOrFinalize(String opKind) async {
  final _ServiceHarness h = _createServiceHarness();
  final _MockNotificationsBloc mockNotifications = _MockNotificationsBloc();
  when(
    () => mockNotifications.addNotification(any()),
  ).thenAnswer((_) async {});
  final bool hadExistingNotifications = sl.isRegistered<NotificationsBloc>();
  final NotificationsBloc? prevNotifications = hadExistingNotifications
      ? sl.get<NotificationsBloc>()
      : null;
  if (hadExistingNotifications) {
    sl.unregister<NotificationsBloc>();
  }
  sl.registerSingleton<NotificationsBloc>(mockNotifications);

  try {
    h.service.create();
    await h.service.init();

    switch (opKind) {
      case 'pair_during_pending_reset':
        // Persist a reset marker and make marker deletion fail so the pending
        // reset stays unresolved when pair() tries to clear it.
        await h.coreStorage.set(
          Web3WalletService.pendingResetStorageKey,
          <String, dynamic>{'pending': true, 'fullReset': true},
        );
        h.coreStorage.shouldFailOnDelete = (String key) =>
            key == Web3WalletService.pendingResetStorageKey;
        try {
          await h.service.pair(
            Uri.parse('wc:abc@2?relay-protocol=irn&symKey=123456'),
          );
          return true;
        } on Object catch (error) {
          if (error is! StateError) rethrow;
          return false;
        }

      case 'approve_during_pending_reset':
        await h.coreStorage.set(
          Web3WalletService.pendingResetStorageKey,
          <String, dynamic>{'pending': true, 'fullReset': true},
        );
        try {
          await h.service.approveSession(
            id: 7,
            namespaces: const <String, Namespace>{},
            pairingTopic: 'p1',
          );
          return true;
        } on Object catch (error) {
          if (error is! StateError) rethrow;
          return false;
        }

      case 'finalize_after_gen_advance':
        final int capturedGen = h.service.resetGeneration;
        await h.service.disconnectEverything();
        final SessionData sess = _buildSession(topic: 'sess-gen');
        h.activeSessions['sess-gen'] = sess;
        return await h.service.finalizeApprovedSession(
          proposalId: 11,
          approveResponse: ApproveResponse(topic: 'sess-gen', session: sess),
          dAppMetadata: const PairingMetadata(
            name: 'dApp',
            description: 'desc',
            url: 'https://example.invalid',
          ),
          expectedResetGeneration: capturedGen,
        );

      case 'finalize_matching_gen':
        final int capturedGen = h.service.resetGeneration;
        final SessionData sess = _buildSession(topic: 'sess-ok');
        h.activeSessions['sess-ok'] = sess;
        return await h.service.finalizeApprovedSession(
          proposalId: 12,
          approveResponse: ApproveResponse(topic: 'sess-ok', session: sess),
          dAppMetadata: const PairingMetadata(
            name: 'dApp',
            description: 'desc',
            url: 'https://example.invalid',
          ),
          expectedResetGeneration: capturedGen,
        );

      default:
        fail('Unknown service op_kind "$opKind"');
    }
  } finally {
    h.service.onDispose();
    if (sl.isRegistered<NotificationsBloc>()) {
      sl.unregister<NotificationsBloc>();
    }
    if (hadExistingNotifications && prevNotifications != null) {
      sl.registerSingleton<NotificationsBloc>(prevNotifications);
    }
  }
}

Future<Map<String, Object>> _runServiceResetMarkerDurability({
  required bool markerWriteOk,
  required bool deleteSucceeds,
}) async {
  final _ServiceHarness h = _createServiceHarness();
  try {
    h.service.create();
    await h.service.init();

    h.activeSessions['sess-r1'] = _buildSession(topic: 'sess-r1');
    bool performedDeletes = false;
    when(
      () => h.walletKit.disconnectSession(
        topic: any(named: 'topic'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => throw StateError('relay offline'));
    when(() => h.sessionStore.delete(any())).thenAnswer((_) async {
      performedDeletes = true;
      if (!deleteSucceeds) {
        throw StateError('session delete failed');
      }
      h.activeSessions.remove('sess-r1');
    });
    h.coreStorage.shouldFailOnSet = (String key) =>
        key == Web3WalletService.pendingResetStorageKey && !markerWriteOk;

    try {
      await h.service.disconnectEverything();
    } on Object {
      // Expected when markerWriteOk is false.
    }

    return <String, Object>{
      'performed_deletes': performedDeletes,
      'marker_cleared': !h.coreStorage.has(
        Web3WalletService.pendingResetStorageKey,
      ),
    };
  } finally {
    h.service.onDispose();
  }
}

Future<Map<String, Object>> _runServiceIdempotentDelivery({
  required bool firstRespondOk,
  required bool sessionActiveOnRetry,
}) async {
  final _ServiceHarness h = _createServiceHarness();
  try {
    h.service.create();
    await h.service.init();

    const String topic = 'sess-idem';
    h.activeSessions[topic] = _buildSession(topic: topic);
    const SessionRequest pending = SessionRequest(
      id: 42,
      topic: topic,
      method: 'znn_send',
      chainId: 'zenon:1',
      params: <String, dynamic>{},
      verifyContext: VerifyContext(
        origin: 'https://dapp.example',
        validation: Validation.VALID,
        verifyUrl: '',
      ),
    );
    h.pendingRequests['42'] = pending;

    int handlerCalls = 0;
    when(
      () => h.nomService.handleZnnSend(
        any(),
        any(),
        requestId: any(named: 'requestId'),
        verifyContext: any(named: 'verifyContext'),
      ),
    ).thenAnswer((_) async {
      handlerCalls += 1;
      return <String, dynamic>{'hash': 'ok-hash'};
    });

    int respondCalls = 0;
    when(
      () => h.walletKit.respondSessionRequest(
        topic: any(named: 'topic'),
        response: any(named: 'response'),
      ),
    ).thenAnswer((_) async {
      respondCalls += 1;
      if (respondCalls == 1 && !firstRespondOk) {
        throw StateError('relay offline');
      }
    });

    h.onSessionRequest.broadcast(
      SessionRequestEvent(
        42,
        topic,
        'znn_send',
        'zenon:1',
        <String, dynamic>{},
        TransportType.relay,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    if (!sessionActiveOnRetry) {
      h.activeSessions.remove(topic);
    }

    // Replay same request id AND simulate relay reconnect.
    h.onSessionRequest.broadcast(
      SessionRequestEvent(
        42,
        topic,
        'znn_send',
        'zenon:1',
        <String, dynamic>{},
        TransportType.relay,
      ),
    );
    h.onRelayConnect.broadcast();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    return <String, Object>{
      'handler_calls': handlerCalls,
      'retried_cached_delivery': respondCalls > 1,
    };
  } finally {
    h.service.onDispose();
  }
}

Future<bool> _runServiceTopicEpochFencing({
  required bool replacementCreated,
}) async {
  final _ServiceHarness h = _createServiceHarness();
  try {
    h.service.create();
    await h.service.init();

    const String topic = 'topic-epoch';
    final Completer<void> hungDisconnect = Completer<void>();
    h.activeSessions[topic] = _buildSession(topic: topic);
    when(
      () => h.walletKit.disconnectSession(
        topic: topic,
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) => hungDisconnect.future);
    when(() => h.sessionStore.delete(topic)).thenAnswer((_) async {
      h.activeSessions.remove(topic);
    });

    // Exhaust reset relay timeout budget so topic unsubscribe is deferred to
    // pendingRelayUnsubscriptionTopics.
    await h.service.disconnectEverything();
    expect(h.service.pendingRelayUnsubscriptionTopics, contains(topic));

    // Settle the old hung disconnect so timed-out topic ops clear before
    // reconnect reconciliation runs.
    hungDisconnect.completeError(StateError('old socket closed'));
    await Future<void>.delayed(Duration.zero);

    int reconcileUnsubs = 0;
    when(() => h.relayClient.isConnected).thenReturn(true);
    when(() => h.relayClient.unsubscribe(topic: topic)).thenAnswer((_) async {
      reconcileUnsubs += 1;
    });

    if (replacementCreated) {
      final SessionData replacement = _buildSession(topic: topic);
      h.activeSessions[topic] = replacement;
      h.onSessionConnect.broadcast(SessionConnect(replacement));
    }

    h.onRelayConnect.broadcast();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Returns true when the deferred unsubscribe was obsolete (skipped).
    return reconcileUnsubs == 0;
  } finally {
    h.service.onDispose();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const JsonRpcResponse<dynamic>(id: 0));
    registerFallbackValue(const ReownSignError(code: 0, message: ''));
    registerFallbackValue(const SessionEventParams(name: '', data: null));
    registerFallbackValue(const PublishOptions(ttl: 0, tag: 0));
    registerFallbackValue(const SubscribeOptions(topic: ''));
    registerFallbackValue(Uri());
    registerFallbackValue(
      WalletNotification(
        title: 't',
        timestamp: 0,
        details: 'd',
        type: NotificationType.paymentSent,
      ),
    );
  });

  group('Bend conformance: $_kDomain', () {
    late Map<String, String> previousAddressMap;
    late int previousChainId;

    setUp(() {
      previousAddressMap = Map<String, String>.from(kAddressLabelMap);
      previousChainId = getChainIdentifier();
      setChainIdentifier();
      kAddressLabelMap = <String, String>{
        'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7': 'Address 1',
      };
    });

    tearDown(() {
      kAddressLabelMap = previousAddressMap;
      setChainIdentifier(chainIdentifier: previousChainId);
    });

    test(
      'all Bend oracle vectors match Syrius WC crash-safety engines',
      () async {
        final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
        final Set<String> seenOps = <String>{};

        for (final Map<String, dynamic> vector in vectors) {
          final String caseId = requireCaseId(vector);
          final String op = requireOp(vector);
          final Map<String, dynamic> args = requireArgs(vector);
          final Object? expected = vector['expected'];
          seenOps.add(op);

          switch (op) {
            case 'store_boot_mode':
              final String actual = await _runStoreBootMode(
                marker: requireString(args, 'marker'),
                clearedAll: requireBool(args, 'cleared_all'),
                hasDeleted: requireBool(args, 'has_deleted'),
                hasReplaced: requireBool(args, 'has_replaced'),
                hasTransientKeys: requireBool(args, 'has_transient_keys'),
                osReadOk: requireBool(args, 'os_read_ok'),
                osReconcileWriteOk: requireBool(
                  args,
                  'os_reconcile_write_ok',
                ),
                fallbackWriteOk: requireBool(args, 'fallback_write_ok'),
                keychainHadEntries: requireBool(args, 'keychain_had_entries'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'store_authoritative_sticky_step':
              final String actual = await _runStoreAuthoritativeStickyStep(
                op: requireString(args, 'op'),
                osOk: requireBool(args, 'os_ok'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'store_isolation_and_delete_all':
              final Map<String, Object> actual =
                  await _runStoreIsolationAndDeleteAll(
                    keyKind: requireString(args, 'key_kind'),
                    ownedPresent: requireBool(args, 'owned_present'),
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'store_reconcile_key_view':
              final Map<String, Object?> actual =
                  await _runStoreReconcileKeyView(
                    clearedAll: requireBool(args, 'cleared_all'),
                    inDeletedKeys: requireBool(args, 'in_deleted_keys'),
                    inReplacedKeys: requireBool(args, 'in_replaced_keys'),
                    osPresent: requireBool(args, 'os_present'),
                    osSubA: args['os_sub_a'] as int?,
                    osSubB: args['os_sub_b'] as int?,
                    trPresent: requireBool(args, 'tr_present'),
                    trSubA: args['tr_sub_a'] as int?,
                    trSubB: args['tr_sub_b'] as int?,
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'store_migration_commit_order':
              final Map<String, Object> actual =
                  await _runStoreMigrationCommitOrder(
                    entriesWriteOk: requireBool(args, 'entries_write_ok'),
                    markerWriteOk: requireBool(args, 'marker_write_ok'),
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'store_reconciliation_cleanup_order':
              final Map<String, Object> actual =
                  await _runStoreReconciliationCleanupOrder(
                    markerDeleteOk: requireBool(args, 'marker_delete_ok'),
                    copiesDeleteOk: requireBool(args, 'copies_delete_ok'),
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'relay_unsubscribe_fencing':
              final Map<String, Object> actual =
                  await _runRelayUnsubscribeFencing(
                    requireString(args, 'scenario'),
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'relay_restore_preserved_id':
              final bool actual = await _runRelayRestorePreservedId(
                hasActiveSub: requireBool(args, 'has_active_sub'),
                hasExistingPreserved: requireBool(
                  args,
                  'has_existing_preserved',
                ),
                hasTopicMapEntry: requireBool(args, 'has_topic_map_entry'),
                persistedIdNonEmpty: requireBool(
                  args,
                  'persisted_id_non_empty',
                ),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'service_reset_admission_and_finalize':
              final bool actual = await _runServiceAdmissionOrFinalize(
                requireString(args, 'op_kind'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'service_reset_marker_durability':
              final Map<String, Object> actual =
                  await _runServiceResetMarkerDurability(
                    markerWriteOk: requireBool(args, 'marker_write_ok'),
                    deleteSucceeds: requireBool(args, 'delete_succeeds'),
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'service_idempotent_request_delivery':
              final Map<String, Object> actual =
                  await _runServiceIdempotentDelivery(
                    firstRespondOk: requireBool(args, 'first_respond_ok'),
                    sessionActiveOnRetry: requireBool(
                      args,
                      'session_active_on_retry',
                    ),
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'service_topic_epoch_fencing':
              final bool actual = await _runServiceTopicEpochFencing(
                replacementCreated: requireBool(args, 'replacement_created'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            default:
              fail('Unhandled Bend conformance op "$_kDomain/$op"');
          }
        }

        expect(
          seenOps,
          equals(<String>{
            'store_boot_mode',
            'store_authoritative_sticky_step',
            'store_isolation_and_delete_all',
            'store_reconcile_key_view',
            'store_migration_commit_order',
            'store_reconciliation_cleanup_order',
            'relay_unsubscribe_fencing',
            'relay_restore_preserved_id',
            'service_reset_admission_and_finalize',
            'service_reset_marker_durability',
            'service_idempotent_request_delivery',
            'service_topic_epoch_fencing',
          }),
        );
      },
    );
  });
}
