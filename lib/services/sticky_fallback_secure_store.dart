import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reown_core/crypto/crypto.dart';
import 'package:reown_core/reown_core.dart';
import 'package:reown_core/store/generic_store.dart';
import 'package:reown_core/store/i_store.dart';

/// Creates a [ReownCore] instance configured with [StickyFallbackSecureStore]
/// before [ReownCore.start] initializes storage and crypto.
///
/// Rebinding [ReownCore.secureStorage] and [ReownCore.crypto] avoids vendoring
/// `reown_core` while preserving desktop keychain fallback persistence across
/// launches.
ReownCore createDesktopReownCore({
  required String projectId,
  bool memoryStore = false,
  LogLevel logLevel = LogLevel.nothing,
  FlutterSecureStorage? secureStorage,
}) {
  final ReownCore core = ReownCore(
    projectId: projectId,
    memoryStore: memoryStore,
    logLevel: logLevel,
  );
  final StickyFallbackSecureStore stickyStore = StickyFallbackSecureStore(
    fallbackStorage: core.storage,
    secureStorage: secureStorage,
  );
  core.secureStorage = stickyStore;
  core.crypto = Crypto(
    core: core,
    keyChain: GenericStore<String>(
      storage: stickyStore,
      context: StoreVersions.CONTEXT_KEYCHAIN,
      version: StoreVersions.VERSION_KEYCHAIN,
      fromJson: (dynamic value) => value as String,
    ),
  );
  return core;
}

/// Secure [IStore] implementation that permanently sticks to its fallback store
/// once secure storage fails (including when keychain reads succeed but writes
/// fail, such as unsandboxed macOS environments).
class StickyFallbackSecureStore implements IStore<Map<String, dynamic>> {
  /// Creates a secure store backed by [FlutterSecureStorage] with sticky
  /// fallback to [_fallbackStorage].
  StickyFallbackSecureStore({
    required this._fallbackStorage,
    Map<String, Map<String, dynamic>>? defaultValue,
    FlutterSecureStorage? secureStorage,
  }) : _map = defaultValue ?? <String, Map<String, dynamic>>{},
       _injectedSecureStorage = secureStorage;

  /// Marker persisted in [_fallbackStorage] once secure storage fails, so
  /// subsequent launches keep reading from fallback instead of treating an
  /// empty keychain as authoritative.
  static const String fallbackFlagKey = 'secure_store_fallback_mode';

  late final FlutterSecureStorage _secureStorage;
  final IStore<Map<String, dynamic>> _fallbackStorage;
  final FlutterSecureStorage? _injectedSecureStorage;
  final Map<String, Map<String, dynamic>> _map;

  bool _initialized = false;
  bool _useFallbackStorage = false;

  /// Whether this store has switched to [_fallbackStorage].
  @visibleForTesting
  bool get isUsingFallback => _useFallbackStorage;

  @override
  Map<String, Map<String, dynamic>> get map => _map;

  @override
  List<String> get keys => _map.keys.toList();

  @override
  List<Map<String, dynamic>> get values => _map.values.toList();

  @override
  String get storagePrefix => ReownConstants.CORE_STORAGE_PREFIX;

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      _secureStorage =
          _injectedSecureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

      if (_fallbackStorage.has(fallbackFlagKey)) {
        _useFallbackStorage = true;
        await _restoreFromFallback();
      } else {
        await _restoreFromSecureStorage();
      }
    } on Object catch (e) {
      debugPrint(
        'StickyFallbackSecureStore: secure storage init/restore failed, '
        'falling back to ${_fallbackStorage.runtimeType}: $e',
      );
      _useFallbackStorage = true;
      await _persistFallbackFlag();
      await _restoreFromFallback();
    }

    _initialized = true;
  }

  @override
  Map<String, dynamic>? get(String key) {
    _checkInitialized();

    final String keyWithPrefix = _addPrefix(key);
    if (_map.containsKey(keyWithPrefix)) {
      return _map[keyWithPrefix];
    }

    // SharedPrefsStores populates its in-memory map lazily on get(), so on a
    // cold relaunch its .keys getter can be empty even though the entry exists
    // in SharedPreferences.
    if (_useFallbackStorage &&
        key != fallbackFlagKey &&
        _fallbackStorage.has(key)) {
      final Map<String, dynamic>? value = _fallbackStorage.get(key);
      if (value != null) {
        _map[keyWithPrefix] = value;
      }
      return value;
    }

    return null;
  }

  @override
  bool has(String key) {
    _checkInitialized();

    final String keyWithPrefix = _addPrefix(key);
    if (_map.containsKey(keyWithPrefix)) {
      return true;
    }

    return _useFallbackStorage &&
        key != fallbackFlagKey &&
        _fallbackStorage.has(key);
  }

  @override
  List<Map<String, dynamic>> getAll() {
    _checkInitialized();
    return values;
  }

  @override
  Future<void> set(String key, Map<String, dynamic> value) async {
    _checkInitialized();

    final String keyWithPrefix = _addPrefix(key);
    _map[keyWithPrefix] = value;

    if (_useFallbackStorage) {
      await _fallbackStorage.set(key, value);
    } else {
      try {
        await _secureStorage.write(
          key: keyWithPrefix,
          value: jsonEncode(value),
        );
      } on Object catch (e) {
        await _switchToFallbackStorage(e);
      }
    }
  }

  @override
  Future<void> update(String key, Map<String, dynamic> value) async {
    _checkInitialized();

    if (!has(key)) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getInternalError(Errors.NO_MATCHING_KEY);
    }

    final String keyWithPrefix = _addPrefix(key);
    _map[keyWithPrefix] = value;

    if (_useFallbackStorage) {
      // Use set() rather than update() so a cold SharedPrefsStores instance
      // whose in-memory map hasn't been hydrated yet still persists cleanly.
      await _fallbackStorage.set(key, value);
    } else {
      try {
        await _secureStorage.write(
          key: keyWithPrefix,
          value: jsonEncode(value),
        );
      } on Object catch (e) {
        await _switchToFallbackStorage(e);
      }
    }
  }

  @override
  Future<void> delete(String key) async {
    _checkInitialized();

    final String keyWithPrefix = _addPrefix(key);
    _map.remove(keyWithPrefix);

    if (_useFallbackStorage) {
      await _fallbackStorage.delete(key);
    } else {
      try {
        await _secureStorage.delete(key: keyWithPrefix);
      } on Object catch (e) {
        await _switchToFallbackStorage(e);
        await _fallbackStorage.delete(key);
      }
    }
  }

  @override
  Future<void> deleteAll() async {
    _checkInitialized();

    final List<String> keysToDelete = List<String>.from(_map.keys);
    _map.clear();

    if (_useFallbackStorage) {
      for (final String keyWithPrefix in keysToDelete) {
        await _fallbackStorage.delete(_removePrefix(keyWithPrefix));
      }
    } else {
      try {
        final Map<String, String> allKeys = await _secureStorage.readAll();
        for (final String key in allKeys.keys) {
          if (key.startsWith(storagePrefix)) {
            await _secureStorage.delete(key: key);
          }
        }
      } on Object catch (e) {
        await _switchToFallbackStorage(e);
        for (final String keyWithPrefix in keysToDelete) {
          await _fallbackStorage.delete(_removePrefix(keyWithPrefix));
        }
      }
    }
  }

  Future<void> _restoreFromSecureStorage() async {
    if (_useFallbackStorage) return;

    final Map<String, String> allKeys = await _secureStorage.readAll();
    for (final MapEntry<String, String> entry in allKeys.entries) {
      if (!entry.key.startsWith(storagePrefix)) {
        continue;
      }
      try {
        final dynamic decodedValue = jsonDecode(entry.value);
        if (decodedValue is Map<String, dynamic>) {
          _map[entry.key] = decodedValue;
        }
      } on Object catch (e) {
        debugPrint(
          'Warning: Failed to decode secure storage value for key '
          '${entry.key}: $e',
        );
      }
    }
  }

  Future<void> _restoreFromFallback() async {
    try {
      for (final String key in _fallbackStorage.keys) {
        if (!key.startsWith(storagePrefix)) {
          continue;
        }
        if (key == _addPrefix(fallbackFlagKey)) {
          continue;
        }
        final Map<String, dynamic>? value = _fallbackStorage.get(
          _removePrefix(key),
        );
        if (value != null) {
          _map[key] = value;
        }
      }
    } on Object catch (e) {
      debugPrint('Warning: Failed to restore from fallback storage: $e');
    }
  }

  Future<void> _switchToFallbackStorage(Object error) async {
    if (_useFallbackStorage) {
      return;
    }

    debugPrint(
      'Warning: Secure storage failed, switching to fallback storage: $error',
    );
    _useFallbackStorage = true;
    await _persistFallbackFlag();

    final List<MapEntry<String, Map<String, dynamic>>> snapshot =
        List<MapEntry<String, Map<String, dynamic>>>.from(_map.entries);
    for (final MapEntry<String, Map<String, dynamic>> entry in snapshot) {
      await _fallbackStorage.set(_removePrefix(entry.key), entry.value);
    }
  }

  Future<void> _persistFallbackFlag() async {
    try {
      await _fallbackStorage.set(fallbackFlagKey, <String, dynamic>{
        'enabled': true,
      });
    } on Object catch (e) {
      debugPrint(
        'Warning: Failed to persist secure storage fallback flag: $e',
      );
    }
  }

  String _addPrefix(String key) => '$storagePrefix$key';

  String _removePrefix(String key) => key.startsWith(storagePrefix)
      ? key.substring(storagePrefix.length)
      : key;

  void _checkInitialized() {
    if (!_initialized) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getInternalError(Errors.NOT_INITIALIZED);
    }
  }
}
