import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reown_core/reown_core.dart';
import 'package:reown_core/store/i_store.dart';
import 'package:zenon_syrius_wallet_flutter/services/sticky_fallback_secure_store.dart';

/// In-memory stand-in for SharedPrefsStores: keys are stored with the core
/// storage prefix internally, public API takes unprefixed keys.
class _MemoryStore implements IStore<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> _data =
      <String, Map<String, dynamic>>{};

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
    _data[_addPrefix(key)] = value;
  }

  @override
  Map<String, dynamic>? get(String key) => _data[_addPrefix(key)];

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

    test(
      'delete and deleteAll preserve fallback stickiness without wiping '
      'unrelated fallback keys',
      () async {
        final _MemoryStore fallback = _MemoryStore();
        await fallback.set('unrelated_pairings', <String, dynamic>{
          'count': 1,
        });

        final _FakeSecureStorage keychain = _FakeSecureStorage(
          failWrites: true,
        );
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
        expect(
          fallback.has(StickyFallbackSecureStore.fallbackFlagKey),
          isTrue,
        );
        expect(
          fallback.get('unrelated_pairings'),
          equals(<String, dynamic>{'count': 1}),
        );
      },
    );

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
  });
}
