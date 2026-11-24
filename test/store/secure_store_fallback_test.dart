import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:reown_core/crypto/crypto.dart';
import 'package:reown_core/reown_core.dart';
import 'package:reown_core/store/generic_store.dart';
import 'package:reown_core/store/i_store.dart';
import 'package:zenon_syrius_wallet_flutter/services/sticky_fallback_secure_store.dart';

/// In-memory stand-in for SharedPrefsStores: keys are stored with the core
/// storage prefix internally, public API takes unprefixed keys.
class _MemoryStore implements IStore<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _data =
      <String, Map<String, dynamic>>{};
  bool Function(String key)? shouldFailOnSet;
  bool Function(String key)? shouldFailOnGet;

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
    _data[_addPrefix(key)] = value;
  }

  @override
  Map<String, dynamic>? get(String key) {
    if (shouldFailOnGet?.call(key) ?? false) {
      throw StateError('fallback get failed for $key');
    }
    return _data[_addPrefix(key)];
  }

  @override
  bool has(String key) => _data.containsKey(_addPrefix(key));

  @override
  List<dynamic> getAll() => values;

  @override
  Future<void> update(String key, Map<String, dynamic> value) async {
    _data[_addPrefix(key)] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(_addPrefix(key));
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

/// Models SharedPrefsStores across a cold app relaunch: [_disk] persists data
/// across launches, while the in-memory [_cache] (and therefore [keys]) starts
/// empty on each new instance until [get] lazily loads an entry.
class _ColdStartSharedPrefsStandIn implements IStore<Map<String, dynamic>> {
  _ColdStartSharedPrefsStandIn(this._disk);

  final Map<String, Map<String, dynamic>> _disk;
  final Map<String, Map<String, dynamic>> _cache =
      <String, Map<String, dynamic>>{};

  @override
  Map<String, Map<String, dynamic>> get map => _cache;

  @override
  List<String> get keys => _cache.keys.toList();

  @override
  List<Map<String, dynamic>> get values => _cache.values.toList();

  @override
  String get storagePrefix => ReownConstants.CORE_STORAGE_PREFIX;

  String _addPrefix(String key) => '$storagePrefix$key';

  @override
  Future<void> init() async {}

  @override
  Future<void> set(String key, Map<String, dynamic> value) async {
    final String prefixed = _addPrefix(key);
    _cache[prefixed] = value;
    _disk[prefixed] = Map<String, dynamic>.from(value);
  }

  @override
  Map<String, dynamic>? get(String key) {
    final String prefixed = _addPrefix(key);
    if (_cache.containsKey(prefixed)) {
      return _cache[prefixed];
    }
    final Map<String, dynamic>? persisted = _disk[prefixed];
    if (persisted != null) {
      final Map<String, dynamic> copy = Map<String, dynamic>.from(persisted);
      _cache[prefixed] = copy;
      return copy;
    }
    // ReownCoreError does not implement Error/Exception upstream.
    // ignore: only_throw_errors
    throw Errors.getInternalError(Errors.NO_MATCHING_KEY);
  }

  @override
  bool has(String key) => _disk.containsKey(_addPrefix(key));

  @override
  List<dynamic> getAll() => values;

  @override
  Future<void> update(String key, Map<String, dynamic> value) async {
    final String prefixed = _addPrefix(key);
    if (!_cache.containsKey(prefixed)) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getInternalError(Errors.NO_MATCHING_KEY);
    }
    _cache[prefixed] = value;
    _disk[prefixed] = Map<String, dynamic>.from(value);
  }

  @override
  Future<void> delete(String key) async {
    final String prefixed = _addPrefix(key);
    _cache.remove(prefixed);
    _disk.remove(prefixed);
  }

  @override
  Future<void> deleteAll() async {
    _cache.clear();
    _disk.clear();
  }
}

/// Fake keychain whose reads and writes can be made to fail independently,
/// mirroring the macOS failure mode where reads succeed but writes fail.
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

void main() {
  group('StickyFallbackSecureStore', () {
    test('stays on secure storage when keychain works', () async {
      final _MemoryStore fallback = _MemoryStore();
      final _FakeSecureStorage keychain = _FakeSecureStorage();

      final StickyFallbackSecureStore store = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: keychain,
      );
      await store.init();
      await store.set('wc_sessions', <String, dynamic>{'topic': 'abc'});

      expect(store.isUsingFallback, isFalse);
      expect(
        store.get('wc_sessions'),
        equals(<String, dynamic>{'topic': 'abc'}),
      );
      expect(keychain.data, isNotEmpty);
      expect(fallback.map, isEmpty);
    });

    test(
      'fallback survives relaunch when keychain reads work but writes fail',
      () async {
        final _MemoryStore fallback = _MemoryStore();

        // Launch 1: reads succeed (empty keychain), writes fail.
        final StickyFallbackSecureStore firstLaunch = StickyFallbackSecureStore(
          fallbackStorage: fallback,
          secureStorage: _FakeSecureStorage(failWrites: true),
        );
        await firstLaunch.init();
        await firstLaunch.set('wc_sessions', <String, dynamic>{'topic': 'abc'});

        expect(firstLaunch.isUsingFallback, isTrue);
        expect(
          firstLaunch.get('wc_sessions'),
          equals(<String, dynamic>{'topic': 'abc'}),
        );

        // Launch 2: keychain reads still succeed and return nothing, because
        // the writes never landed. The store must keep using the fallback
        // instead of treating the empty keychain as authoritative.
        final StickyFallbackSecureStore secondLaunch =
            StickyFallbackSecureStore(
              fallbackStorage: fallback,
              secureStorage: _FakeSecureStorage(),
            );
        await secondLaunch.init();

        expect(secondLaunch.isUsingFallback, isTrue);
        expect(
          secondLaunch.get('wc_sessions'),
          equals(<String, dynamic>{'topic': 'abc'}),
        );
      },
    );

    test(
      'fallback survives relaunch after an initial restore failure',
      () async {
        final _MemoryStore fallback = _MemoryStore();

        // Launch 1: keychain reads fail entirely; data goes to the fallback.
        final StickyFallbackSecureStore firstLaunch = StickyFallbackSecureStore(
          fallbackStorage: fallback,
          secureStorage: _FakeSecureStorage(failReads: true),
        );
        await firstLaunch.init();
        await firstLaunch.set('wc_sessions', <String, dynamic>{'topic': 'abc'});

        // Launch 2: keychain recovered but is empty; the fallback still holds
        // the authoritative state and must keep being used.
        final StickyFallbackSecureStore secondLaunch =
            StickyFallbackSecureStore(
              fallbackStorage: fallback,
              secureStorage: _FakeSecureStorage(),
            );
        await secondLaunch.init();

        expect(secondLaunch.isUsingFallback, isTrue);
        expect(
          secondLaunch.get('wc_sessions'),
          equals(<String, dynamic>{'topic': 'abc'}),
        );
      },
    );

    test(
      'cold relaunch with lazy SharedPrefsStores still restores fallback data',
      () async {
        final Map<String, Map<String, dynamic>> disk =
            <String, Map<String, dynamic>>{};

        // Launch 1: write fails -> persisted to disk via fallback.
        final _ColdStartSharedPrefsStandIn fallback1 =
            _ColdStartSharedPrefsStandIn(disk);
        final StickyFallbackSecureStore firstLaunch = StickyFallbackSecureStore(
          fallbackStorage: fallback1,
          secureStorage: _FakeSecureStorage(failWrites: true),
        );
        await firstLaunch.init();
        await firstLaunch.set('keychain', <String, dynamic>{'k1': 'secret'});

        // Launch 2: brand-new SharedPrefsStores instance whose in-memory keys
        // start empty until get() is called.
        final _ColdStartSharedPrefsStandIn fallback2 =
            _ColdStartSharedPrefsStandIn(disk);
        expect(fallback2.keys, isEmpty);

        final StickyFallbackSecureStore secondLaunch =
            StickyFallbackSecureStore(
              fallbackStorage: fallback2,
              secureStorage: _FakeSecureStorage(),
            );
        await secondLaunch.init();

        expect(secondLaunch.isUsingFallback, isTrue);
        expect(secondLaunch.has('keychain'), isTrue);
        expect(
          secondLaunch.get('keychain'),
          equals(<String, dynamic>{'k1': 'secret'}),
        );
        expect(
          secondLaunch.has(StickyFallbackSecureStore.fallbackFlagKey),
          isFalse,
        );

        // Updating a lazily restored key works without throwing
        // NO_MATCHING_KEY.
        await secondLaunch.update('keychain', <String, dynamic>{
          'k1': 'rotated',
        });
        expect(
          secondLaunch.get('keychain'),
          equals(<String, dynamic>{'k1': 'rotated'}),
        );
      },
    );

    test('delete and deleteAll preserve fallback stickiness without wiping '
        'unrelated fallback keys', () async {
      final _MemoryStore fallback = _MemoryStore();
      await fallback.set('unrelated_pairings', <String, dynamic>{'count': 1});

      final _FakeSecureStorage keychain = _FakeSecureStorage(failWrites: true);
      final StickyFallbackSecureStore store = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: keychain,
      );
      await store.init();
      await store.set('k1', <String, dynamic>{'v': 1});
      await store.set('k2', <String, dynamic>{'v': 2});

      await store.delete('k1');
      expect(store.has('k1'), isFalse);
      expect(store.has('k2'), isTrue);

      await store.deleteAll();
      expect(store.has('k2'), isFalse);
      expect(fallback.has(StickyFallbackSecureStore.fallbackFlagKey), isTrue);
      expect(
        fallback.get('unrelated_pairings'),
        equals(<String, dynamic>{'count': 1}),
      );
    });

    test(
      'createDesktopReownCore wires StickyFallbackSecureStore into crypto',
      () async {
        final _FakeSecureStorage keychain = _FakeSecureStorage(
          failWrites: true,
        );
        final ReownCore core = createDesktopReownCore(
          projectId: 'synthetic-project-id',
          memoryStore: true,
          secureStorage: keychain,
        );

        expect(core.secureStorage, isA<StickyFallbackSecureStore>());
        await core.storage.init();
        await core.secureStorage.init();
        await core.crypto.init();

        final String publicKey = await core.crypto.generateKeyPair();
        expect(publicKey, isNotEmpty);
        expect(
          (core.secureStorage as StickyFallbackSecureStore).isUsingFallback,
          isTrue,
        );
        expect(
          core.storage.has(StickyFallbackSecureStore.fallbackFlagKey),
          isTrue,
        );
      },
    );

    test('migrates pre-existing keychain entries alongside triggering write '
        'when keychain later fails', () async {
      final _MemoryStore fallback = _MemoryStore();
      final _FakeSecureStorage keychain = _FakeSecureStorage(
        initialData: <String, String>{
          '${ReownConstants.CORE_STORAGE_PREFIX}existing_key':
              '{"secret":"old"}',
        },
      );

      final StickyFallbackSecureStore store = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: keychain,
      );
      await store.init();
      expect(store.isUsingFallback, isFalse);
      expect(
        store.get('existing_key'),
        equals(<String, dynamic>{'secret': 'old'}),
      );

      keychain.failWrites = true;
      await store.set('new_key', <String, dynamic>{'secret': 'new'});

      expect(store.isUsingFallback, isTrue);
      expect(fallback.has(StickyFallbackSecureStore.fallbackFlagKey), isTrue);
      expect(
        fallback.get('existing_key'),
        equals(<String, dynamic>{'secret': 'old'}),
      );
      expect(
        fallback.get('new_key'),
        equals(<String, dynamic>{'secret': 'new'}),
      );
    });

    test('transient initial readAll failure does not permanently lock out '
        'keychain when no writes occur', () async {
      final _MemoryStore fallback = _MemoryStore();
      final _FakeSecureStorage keychain = _FakeSecureStorage(
        failReads: true,
        initialData: <String, String>{
          '${ReownConstants.CORE_STORAGE_PREFIX}keychain': '{"k":"v1"}',
        },
      );

      final StickyFallbackSecureStore firstLaunch = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: keychain,
      );
      await firstLaunch.init();
      expect(firstLaunch.isUsingFallback, isTrue);
      expect(fallback.has(StickyFallbackSecureStore.fallbackFlagKey), isFalse);

      // Next launch: keychain recovered and no mutations landed in fallback.
      keychain.failReads = false;
      final StickyFallbackSecureStore secondLaunch = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: keychain,
      );
      await secondLaunch.init();

      expect(secondLaunch.isUsingFallback, isFalse);
      expect(
        secondLaunch.get('keychain'),
        equals(<String, dynamic>{'k': 'v1'}),
      );
    });

    test(
      'transient initial readAll failure through GenericStore still recovers '
      'OS keychain entries on relaunch',
      () async {
        final Map<String, Map<String, dynamic>> disk =
            <String, Map<String, dynamic>>{};
        final _FakeSecureStorage keychain = _FakeSecureStorage();

        // Launch 0: healthy OS keychain stores a real WalletConnect key via
        // ReownCore's GenericStore<String>.
        final _ColdStartSharedPrefsStandIn storage0 =
            _ColdStartSharedPrefsStandIn(disk);
        final StickyFallbackSecureStore secure0 = StickyFallbackSecureStore(
          fallbackStorage: storage0,
          secureStorage: keychain,
        );
        final ReownCore core0 =
            ReownCore(projectId: 'synthetic-project-id', memoryStore: true)
              ..storage = storage0
              ..secureStorage = secure0;
        final GenericStore<String> keyChain0 = GenericStore<String>(
          storage: secure0,
          context: StoreVersions.CONTEXT_KEYCHAIN,
          version: StoreVersions.VERSION_KEYCHAIN,
          fromJson: (dynamic value) => value as String,
        );
        core0.crypto = Crypto(core: core0, keyChain: keyChain0);
        await core0.storage.init();
        await core0.secureStorage.init();
        await core0.crypto.init();
        await keyChain0.set('topicA', 'secret-sym-key');
        expect(secure0.isUsingFallback, isFalse);

        // Launch 1: OS keychain transiently fails readAll(). GenericStore.init
        // writes its empty version/data bootstrap and generateKeyPair writes a
        // seed into fallback storage; both must stay non-authoritative so
        // Launch 2 retries the OS keychain.
        keychain.failReads = true;
        final _ColdStartSharedPrefsStandIn storage1 =
            _ColdStartSharedPrefsStandIn(disk);
        final StickyFallbackSecureStore secure1 = StickyFallbackSecureStore(
          fallbackStorage: storage1,
          secureStorage: keychain,
        );
        final ReownCore core1 =
            ReownCore(projectId: 'synthetic-project-id', memoryStore: true)
              ..storage = storage1
              ..secureStorage = secure1;
        core1.crypto = Crypto(
          core: core1,
          keyChain: GenericStore<String>(
            storage: secure1,
            context: StoreVersions.CONTEXT_KEYCHAIN,
            version: StoreVersions.VERSION_KEYCHAIN,
            fromJson: (dynamic value) => value as String,
          ),
        );
        await core1.storage.init();
        await core1.secureStorage.init();
        await core1.crypto.init();
        await core1.crypto.generateKeyPair();
        expect(secure1.isUsingFallback, isTrue);

        // Launch 2: OS keychain recovers. Existing key `topicA` must be
        // restored from secure storage and transient fallback copies cleaned.
        keychain.failReads = false;
        final _ColdStartSharedPrefsStandIn storage2 =
            _ColdStartSharedPrefsStandIn(disk);
        final StickyFallbackSecureStore secure2 = StickyFallbackSecureStore(
          fallbackStorage: storage2,
          secureStorage: keychain,
        );
        final ReownCore core2 =
            ReownCore(projectId: 'synthetic-project-id', memoryStore: true)
              ..storage = storage2
              ..secureStorage = secure2;
        final GenericStore<String> keyChain2 = GenericStore<String>(
          storage: secure2,
          context: StoreVersions.CONTEXT_KEYCHAIN,
          version: StoreVersions.VERSION_KEYCHAIN,
          fromJson: (dynamic value) => value as String,
        );
        core2.crypto = Crypto(core: core2, keyChain: keyChain2);
        await core2.storage.init();
        await core2.secureStorage.init();
        await core2.crypto.init();

        expect(secure2.isUsingFallback, isFalse);
        expect(keyChain2.get('topicA'), 'secret-sym-key');
        expect(
          storage2.has(StickyFallbackSecureStore.fallbackFlagKey),
          isFalse,
        );
      },
    );

    test('fallback init ignores unrelated core entries and deleteAll preserves '
        'them even after a cold relaunch', () async {
      final Map<String, Map<String, dynamic>> disk =
          <String, Map<String, dynamic>>{};

      // Launch 1: populate both unrelated core data and secure-store data in
      // fallback storage.
      final _ColdStartSharedPrefsStandIn fallback1 =
          _ColdStartSharedPrefsStandIn(disk);
      await fallback1.set('unrelated_pairings', <String, dynamic>{'count': 2});
      final StickyFallbackSecureStore firstLaunch = StickyFallbackSecureStore(
        fallbackStorage: fallback1,
        secureStorage: _FakeSecureStorage(failWrites: true),
      );
      await firstLaunch.init();
      await firstLaunch.set('k1', <String, dynamic>{'v': 1});
      await firstLaunch.set('k2', <String, dynamic>{'v': 2});

      // Launch 2: cold start (empty in-memory cache). Verify unrelated core
      // entries are NOT imported, and calling deleteAll() immediately wipes
      // persisted secure-store keys without touching unrelated_pairings.
      final _ColdStartSharedPrefsStandIn fallback2 =
          _ColdStartSharedPrefsStandIn(disk);
      final StickyFallbackSecureStore secondLaunch = StickyFallbackSecureStore(
        fallbackStorage: fallback2,
        secureStorage: _FakeSecureStorage(),
      );
      await secondLaunch.init();

      expect(secondLaunch.isUsingFallback, isTrue);
      expect(secondLaunch.has('unrelated_pairings'), isFalse);
      expect(secondLaunch.get('unrelated_pairings'), isNull);

      await secondLaunch.deleteAll();

      expect(secondLaunch.has('k1'), isFalse);
      expect(secondLaunch.has('k2'), isFalse);
      expect(fallback2.has('k1'), isFalse);
      expect(fallback2.has('k2'), isFalse);
      expect(fallback2.has(StickyFallbackSecureStore.fallbackFlagKey), isTrue);
      expect(
        fallback2.get('unrelated_pairings'),
        equals(<String, dynamic>{'count': 2}),
      );

      // Launch 3 confirms deleted keys do not reappear from disk.
      final _ColdStartSharedPrefsStandIn fallback3 =
          _ColdStartSharedPrefsStandIn(disk);
      final StickyFallbackSecureStore thirdLaunch = StickyFallbackSecureStore(
        fallbackStorage: fallback3,
        secureStorage: _FakeSecureStorage(),
      );
      await thirdLaunch.init();
      expect(thirdLaunch.isUsingFallback, isTrue);
      expect(thirdLaunch.has('k1'), isFalse);
      expect(thirdLaunch.has('k2'), isFalse);
      expect(
        fallback3.get('unrelated_pairings'),
        equals(<String, dynamic>{'count': 2}),
      );
    });

    test('failed mid-migration entry copy remains resumable without persisting '
        'an incomplete fallback marker', () async {
      final _MemoryStore fallback = _MemoryStore();
      final _FakeSecureStorage keychain = _FakeSecureStorage(
        initialData: <String, String>{
          '${ReownConstants.CORE_STORAGE_PREFIX}existing_1': '{"v":1}',
          '${ReownConstants.CORE_STORAGE_PREFIX}existing_2': '{"v":2}',
        },
      );
      final StickyFallbackSecureStore store = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: keychain,
      );
      await store.init();

      keychain.failWrites = true;
      fallback.shouldFailOnSet = (String key) => key == 'existing_2';

      await expectLater(
        store.set('new_key', <String, dynamic>{'v': 3}),
        throwsStateError,
      );
      expect(store.isUsingFallback, isFalse);
      expect(fallback.has(StickyFallbackSecureStore.fallbackFlagKey), isFalse);

      // Retry once fallback recovers: all pre-existing entries and new_key
      // are copied before the marker is committed.
      fallback.shouldFailOnSet = null;
      await store.set('new_key', <String, dynamic>{'v': 3});

      expect(store.isUsingFallback, isTrue);
      expect(fallback.has(StickyFallbackSecureStore.fallbackFlagKey), isTrue);
      expect(fallback.get('existing_1'), equals(<String, dynamic>{'v': 1}));
      expect(fallback.get('existing_2'), equals(<String, dynamic>{'v': 2}));
      expect(fallback.get('new_key'), equals(<String, dynamic>{'v': 3}));
    });

    test(
      'propagates fallback marker persistence failure and logs fallback switch '
      'through Logger',
      () async {
        final List<LogRecord> warnings = <LogRecord>[];
        final StreamSubscription<LogRecord> sub =
            Logger('StickyFallbackSecureStore').onRecord.listen((
              LogRecord record,
            ) {
              if (record.level >= Level.WARNING) {
                warnings.add(record);
              }
            });
        addTearDown(sub.cancel);

        final _MemoryStore fallback = _MemoryStore();
        final _FakeSecureStorage keychain = _FakeSecureStorage(
          failWrites: true,
        );
        final StickyFallbackSecureStore store = StickyFallbackSecureStore(
          fallbackStorage: fallback,
          secureStorage: keychain,
        );
        await store.init();

        fallback.shouldFailOnSet = (String key) =>
            key == StickyFallbackSecureStore.fallbackFlagKey;

        await expectLater(
          store.set('wc_key', <String, dynamic>{'k': 'secret'}),
          throwsStateError,
        );
        expect(store.isUsingFallback, isFalse);
        expect(
          fallback.has(StickyFallbackSecureStore.fallbackFlagKey),
          isFalse,
        );
        expect(
          warnings.any(
            (LogRecord r) => r.message.contains(
              'switching WalletConnect secure store to fallback storage',
            ),
          ),
          isTrue,
        );
        expect(
          warnings.any(
            (LogRecord r) => r.message.contains(
              'Failed to persist secure storage fallback marker',
            ),
          ),
          isTrue,
        );

        // Subsequent retry succeeds once fallback marker writes work.
        fallback.shouldFailOnSet = null;
        await store.set('wc_key', <String, dynamic>{'k': 'secret'});
        expect(store.isUsingFallback, isTrue);
        expect(fallback.has(StickyFallbackSecureStore.fallbackFlagKey), isTrue);
        expect(store.get('wc_key'), equals(<String, dynamic>{'k': 'secret'}));
      },
    );

    test('reconciles new transient pairing keys and tombstones into recovered '
        'OS keychain without losing existing OS keychain entries', () async {
      final Map<String, Map<String, dynamic>> disk =
          <String, Map<String, dynamic>>{};
      final _FakeSecureStorage keychain = _FakeSecureStorage(
        failReads: true,
        initialData: <String, String>{
          '${ReownConstants.CORE_STORAGE_PREFIX}0.3//keychain':
              '{"topicA":"os-sym-a"}',
          '${ReownConstants.CORE_STORAGE_PREFIX}obsolete_key': '{"v":0}',
        },
      );

      // Launch 1: OS keychain transiently fails readAll(); user pairs a new
      // dApp (topicB) and deletes obsolete_key.
      final _ColdStartSharedPrefsStandIn storage1 =
          _ColdStartSharedPrefsStandIn(disk);
      final StickyFallbackSecureStore launch1 = StickyFallbackSecureStore(
        fallbackStorage: storage1,
        secureStorage: keychain,
      );
      await launch1.init();
      await launch1.set('0.3//keychain', <String, dynamic>{
        'topicB': 'transient-sym-b',
      });
      await launch1.delete('obsolete_key');

      // Launch 2: OS keychain recovers. Both topicA and topicB must be
      // present in OS keychain, while obsolete_key stays deleted.
      keychain.failReads = false;
      final _ColdStartSharedPrefsStandIn storage2 =
          _ColdStartSharedPrefsStandIn(disk);
      final StickyFallbackSecureStore launch2 = StickyFallbackSecureStore(
        fallbackStorage: storage2,
        secureStorage: keychain,
      );
      await launch2.init();

      expect(launch2.isUsingFallback, isFalse);
      expect(
        launch2.get('0.3//keychain'),
        equals(<String, dynamic>{
          'topicA': 'os-sym-a',
          'topicB': 'transient-sym-b',
        }),
      );
      expect(launch2.has('obsolete_key'), isFalse);
      expect(storage2.has(StickyFallbackSecureStore.fallbackFlagKey), isFalse);
    });

    test(
      'promotes reconciled state (OS entries + transient writes - tombstones) '
      'into authoritative fallback when OS reads succeed but writes fail',
      () async {
        final Map<String, Map<String, dynamic>> disk =
            <String, Map<String, dynamic>>{};
        final _FakeSecureStorage keychain = _FakeSecureStorage(
          failReads: true,
          initialData: <String, String>{
            '${ReownConstants.CORE_STORAGE_PREFIX}0.3//keychain':
                '{"topicA":"os-sym-a"}',
            '${ReownConstants.CORE_STORAGE_PREFIX}obsolete_key': '{"v":0}',
          },
        );

        // Launch 1: OS keychain read fails; transient writes & delete occur.
        final _ColdStartSharedPrefsStandIn storage1 =
            _ColdStartSharedPrefsStandIn(disk);
        final StickyFallbackSecureStore launch1 = StickyFallbackSecureStore(
          fallbackStorage: storage1,
          secureStorage: keychain,
        );
        await launch1.init();
        await launch1.set('0.3//keychain', <String, dynamic>{
          'topicB': 'transient-sym-b',
        });
        await launch1.delete('obsolete_key');

        // Launch 2: OS keychain reads succeed, but writes/deletes are denied.
        keychain
          ..failReads = false
          ..failWrites = true;
        final _ColdStartSharedPrefsStandIn storage2 =
            _ColdStartSharedPrefsStandIn(disk);
        final StickyFallbackSecureStore launch2 = StickyFallbackSecureStore(
          fallbackStorage: storage2,
          secureStorage: keychain,
        );
        await launch2.init();

        expect(launch2.isUsingFallback, isTrue);
        expect(
          launch2.get('0.3//keychain'),
          equals(<String, dynamic>{
            'topicA': 'os-sym-a',
            'topicB': 'transient-sym-b',
          }),
        );
        expect(launch2.has('obsolete_key'), isFalse);
        expect(
          storage2.get(
            StickyFallbackSecureStore.fallbackFlagKey,
          )?['authoritative'],
          isTrue,
        );
      },
    );

    test(
      'serializes concurrent fallback set() calls so both keys remain in the '
      'persisted manifest and preserves unrelated core entries on delete()',
      () async {
        final _MemoryStore fallback = _MemoryStore();
        await fallback.set('unrelated_pairings', <String, dynamic>{'keep': 1});

        final StickyFallbackSecureStore store = StickyFallbackSecureStore(
          fallbackStorage: fallback,
          secureStorage: _FakeSecureStorage(failWrites: true),
        );
        await store.init();

        await Future.wait<void>(<Future<void>>[
          store.set('k1', <String, dynamic>{'v': 1}),
          store.set('k2', <String, dynamic>{'v': 2}),
          store.set('k3', <String, dynamic>{'v': 3}),
        ]);

        // Deleting an unowned key in manifested fallback mode must not touch
        // unrelated core entries.
        await store.delete('unrelated_pairings');
        expect(
          fallback.get('unrelated_pairings'),
          equals(<String, dynamic>{'keep': 1}),
        );

        final StickyFallbackSecureStore relaunched = StickyFallbackSecureStore(
          fallbackStorage: fallback,
          secureStorage: _FakeSecureStorage(),
        );
        await relaunched.init();
        expect(relaunched.get('k1'), equals(<String, dynamic>{'v': 1}));
        expect(relaunched.get('k2'), equals(<String, dynamic>{'v': 2}));
        expect(relaunched.get('k3'), equals(<String, dynamic>{'v': 3}));
      },
    );

    test('preserves unread legacy keys across single-key writes and fails init '
        'when a present fallback marker cannot be read', () async {
      final _MemoryStore fallback = _MemoryStore();
      await fallback.set(
        StickyFallbackSecureStore.fallbackFlagKey,
        <String, dynamic>{'enabled': true},
      );
      await fallback.set('legacy_a', <String, dynamic>{'v': 'a'});
      await fallback.set('legacy_b', <String, dynamic>{'v': 'b'});

      final StickyFallbackSecureStore legacyStore = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: _FakeSecureStorage(),
      );
      await legacyStore.init();
      expect(legacyStore.get('legacy_a'), equals(<String, dynamic>{'v': 'a'}));
      await legacyStore.set('legacy_a', <String, dynamic>{'v': 'a2'});
      // Unread legacy_b must still be readable after updating legacy_a.
      expect(legacyStore.get('legacy_b'), equals(<String, dynamic>{'v': 'b'}));

      // Present but unreadable marker must fail init instead of selecting
      // an empty OS keychain.
      fallback.shouldFailOnGet = (String key) =>
          key == StickyFallbackSecureStore.fallbackFlagKey;
      final StickyFallbackSecureStore failingInit = StickyFallbackSecureStore(
        fallbackStorage: fallback,
        secureStorage: _FakeSecureStorage(),
      );
      await expectLater(failingInit.init(), throwsStateError);
    });

    test('omits raw JSON exception payload from decode failure warning logs '
        '(CWE-532)', () async {
      final List<LogRecord> warnings = <LogRecord>[];
      final StreamSubscription<LogRecord> sub =
          Logger('StickyFallbackSecureStore').onRecord.listen((
            LogRecord record,
          ) {
            if (record.level >= Level.WARNING) {
              warnings.add(record);
            }
          });
      addTearDown(sub.cancel);

      final StickyFallbackSecureStore store = StickyFallbackSecureStore(
        fallbackStorage: _MemoryStore(),
        secureStorage: _FakeSecureStorage(
          initialData: <String, String>{
            '${ReownConstants.CORE_STORAGE_PREFIX}keychain':
                '{"secret":"SUPER_SENSITIVE_SYM_KEY_DO_NOT_LOG',
          },
        ),
      );
      await store.init();

      expect(warnings, isNotEmpty);
      for (final LogRecord record in warnings) {
        expect(record.message, isNot(contains('SUPER_SENSITIVE_SYM_KEY')));
        expect(record.error, isNull);
      }
    });
  });
}
