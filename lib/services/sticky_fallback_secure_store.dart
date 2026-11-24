import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
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

  /// Marker persisted in [_fallbackStorage] once fallback storage becomes
  /// authoritative, including the manifest of unprefixed keys owned by this
  /// store so subsequent launches restore and delete only secure-store entries
  /// without touching unrelated keys sharing [_fallbackStorage].
  static const String fallbackFlagKey = 'secure_store_fallback_mode';

  static const String _fallbackKeysField = 'keys';
  static const String _fallbackAuthoritativeField = 'authoritative';

  final Logger _logger = Logger('StickyFallbackSecureStore');
  late final FlutterSecureStorage _secureStorage;
  final IStore<Map<String, dynamic>> _fallbackStorage;
  final FlutterSecureStorage? _injectedSecureStorage;
  final Map<String, Map<String, dynamic>> _map;
  final Set<String> _ownedFallbackKeys = <String>{};

  bool _initialized = false;
  bool _useFallbackStorage = false;
  bool _fallbackPersisted = false;
  bool _fallbackAuthoritative = false;
  bool _hasFallbackKeyManifest = false;

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

    _secureStorage =
        _injectedSecureStorage ??
        const FlutterSecureStorage(
          aOptions: AndroidOptions(resetOnError: false),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

    final Map<String, dynamic>? existingFlag =
        _fallbackStorage.has(fallbackFlagKey) ? _safeGetFallbackFlag() : null;
    // Legacy markers written without an `authoritative` field are treated as
    // authoritative to preserve stickiness across upgrades.
    final bool hasAuthoritativeFlag =
        existingFlag != null &&
        ((existingFlag[_fallbackAuthoritativeField] as bool?) ?? true);

    if (hasAuthoritativeFlag) {
      _useFallbackStorage = true;
      _fallbackPersisted = true;
      _fallbackAuthoritative = true;
      await _restoreFromFallback(flagData: existingFlag);
      _initialized = true;
      return;
    }

    try {
      await _restoreFromSecureStorage();

      if (existingFlag != null) {
        final List<String> transientKeys = _extractManifestKeys(existingFlag);
        if (_map.isNotEmpty || transientKeys.isEmpty) {
          // OS keychain recovered with existing entries (or transient fallback
          // holds no entries): keep secure storage authoritative and purge any
          // stale transient fallback copies.
          await _clearTransientFallbackData(transientKeys);
        } else {
          // Keychain succeeded empty while a prior transient fallback holds
          // persisted data (e.g., first launch failed readAll and wrote new
          // session keys): restore those fallback entries instead of dropping
          // them, while keeping `authoritative: false` unless writes fail.
          _useFallbackStorage = true;
          _fallbackPersisted = true;
          _fallbackAuthoritative = false;
          await _restoreFromFallback(flagData: existingFlag);
        }
      }
    } on Object catch (e) {
      // Do not mark fallback authoritative on a startup read failure: even if
      // Reown's GenericStore initializes empty metadata during this session,
      // the next launch must still retry the OS keychain so existing keys are
      // recovered once the keychain is unlocked/available again.
      _logger.warning(
        'Secure storage init/restore failed, using non-authoritative fallback '
        '(${_fallbackStorage.runtimeType})',
        e,
      );
      _useFallbackStorage = true;
      _fallbackAuthoritative = false;
      if (existingFlag != null) {
        _fallbackPersisted = true;
        await _restoreFromFallback(flagData: existingFlag);
      } else {
        _fallbackPersisted = false;
        _hasFallbackKeyManifest = true;
      }
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
    // in SharedPreferences. Only read keys owned by this store (or legacy
    // pre-manifest entries when upgrading from an older fallback flag).
    if (_canLazyReadFromFallback(key) && _fallbackStorage.has(key)) {
      final Map<String, dynamic>? value = _fallbackStorage.get(key);
      if (value != null) {
        _ownedFallbackKeys.add(key);
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

    return _canLazyReadFromFallback(key) && _fallbackStorage.has(key);
  }

  @override
  List<Map<String, dynamic>> getAll() {
    _checkInitialized();
    return values;
  }

  @override
  Future<void> set(String key, Map<String, dynamic> value) async {
    _checkInitialized();
    await _persistEntry(key, value);
  }

  @override
  Future<void> update(String key, Map<String, dynamic> value) async {
    _checkInitialized();

    if (!has(key)) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getInternalError(Errors.NO_MATCHING_KEY);
    }

    await _persistEntry(key, value);
  }

  Future<void> _persistEntry(String key, Map<String, dynamic> value) async {
    final String keyWithPrefix = _addPrefix(key);

    if (_useFallbackStorage) {
      // Use set() rather than update() so a cold SharedPrefsStores instance
      // whose in-memory map hasn't been hydrated yet still persists cleanly.
      await _fallbackStorage.set(key, value);

      final Set<String> nextOwnedKeys = Set<String>.from(_ownedFallbackKeys)
        ..add(key);
      final bool needsFlagWrite =
          !_fallbackPersisted ||
          !_hasFallbackKeyManifest ||
          !_ownedFallbackKeys.contains(key);
      if (needsFlagWrite) {
        await _persistFallbackFlag(
          nextOwnedKeys,
          authoritative: _fallbackAuthoritative,
        );
        _fallbackPersisted = true;
        _hasFallbackKeyManifest = true;
      }

      _ownedFallbackKeys.add(key);
      _map[keyWithPrefix] = value;
      return;
    }

    try {
      await _secureStorage.write(key: keyWithPrefix, value: jsonEncode(value));
      _map[keyWithPrefix] = value;
    } on Object catch (e) {
      await _migrateAndCommitFallback(
        error: e,
        extraEntries: <String, Map<String, dynamic>>{key: value},
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    _checkInitialized();

    final String keyWithPrefix = _addPrefix(key);

    if (_useFallbackStorage) {
      await _fallbackStorage.delete(key);

      final Set<String> nextOwnedKeys = Set<String>.from(_ownedFallbackKeys)
        ..remove(key);
      final bool needsFlagWrite =
          !_fallbackPersisted ||
          !_hasFallbackKeyManifest ||
          _ownedFallbackKeys.contains(key);
      if (needsFlagWrite) {
        if (!_fallbackAuthoritative && nextOwnedKeys.isEmpty) {
          await _fallbackStorage.delete(fallbackFlagKey);
          _fallbackPersisted = false;
        } else {
          await _persistFallbackFlag(
            nextOwnedKeys,
            authoritative: _fallbackAuthoritative,
          );
          _fallbackPersisted = true;
        }
        _hasFallbackKeyManifest = true;
      }

      _ownedFallbackKeys.remove(key);
      _map.remove(keyWithPrefix);
      return;
    }

    try {
      await _secureStorage.delete(key: keyWithPrefix);
      _map.remove(keyWithPrefix);
    } on Object catch (e) {
      await _migrateAndCommitFallback(error: e, keysToRemove: <String>{key});
    }
  }

  @override
  Future<void> deleteAll() async {
    _checkInitialized();

    if (_useFallbackStorage) {
      final Set<String> keysToDelete = <String>{
        ..._ownedFallbackKeys,
        ..._map.keys.map(_removePrefix),
      };
      for (final String unprefixedKey in keysToDelete) {
        await _fallbackStorage.delete(unprefixedKey);
      }

      if (_fallbackAuthoritative) {
        await _persistFallbackFlag(const <String>{}, authoritative: true);
        _fallbackPersisted = true;
      } else {
        await _fallbackStorage.delete(fallbackFlagKey);
        _fallbackPersisted = false;
      }
      _hasFallbackKeyManifest = true;
      _ownedFallbackKeys.clear();
      _map.clear();
      return;
    }

    try {
      final Map<String, String> allKeys = await _secureStorage.readAll();
      for (final String key in allKeys.keys) {
        if (key.startsWith(storagePrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
      _map.clear();
    } on Object catch (e) {
      await _migrateAndCommitFallback(
        error: e,
        keysToRemove: _map.keys.map(_removePrefix).toSet(),
      );
    }
  }

  bool _canLazyReadFromFallback(String key) {
    if (!_useFallbackStorage || key == fallbackFlagKey) {
      return false;
    }
    if (_hasFallbackKeyManifest) {
      return _ownedFallbackKeys.contains(key);
    }
    return true;
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
        _logger.warning(
          'Failed to decode secure storage value for key ${entry.key}',
          e,
        );
      }
    }
  }

  Map<String, dynamic>? _safeGetFallbackFlag() {
    try {
      return _fallbackStorage.get(fallbackFlagKey);
    } on Object catch (e) {
      _logger.warning('Failed to read fallback marker from storage', e);
      return null;
    }
  }

  List<String> _extractManifestKeys(Map<String, dynamic> flagData) {
    final Object? rawKeys = flagData[_fallbackKeysField];
    if (rawKeys is! List) {
      return const <String>[];
    }
    return rawKeys
        .whereType<String>()
        .where((String key) => key.isNotEmpty && key != fallbackFlagKey)
        .toList();
  }

  Future<void> _clearTransientFallbackData(List<String> transientKeys) async {
    try {
      for (final String key in transientKeys) {
        await _fallbackStorage.delete(key);
      }
      await _fallbackStorage.delete(fallbackFlagKey);
    } on Object catch (e) {
      _logger.warning('Failed to clean up transient fallback entries', e);
    }
  }

  Future<void> _restoreFromFallback({Map<String, dynamic>? flagData}) async {
    try {
      final Map<String, dynamic>? resolvedFlag =
          flagData ??
          (_fallbackStorage.has(fallbackFlagKey)
              ? _fallbackStorage.get(fallbackFlagKey)
              : null);
      final Object? rawKeys = resolvedFlag?[_fallbackKeysField];
      if (rawKeys is! List) {
        // Legacy fallback flag without an explicit key manifest: avoid
        // scanning unrelated keys in _fallbackStorage; entries will hydrate
        // lazily on explicit get() calls.
        _hasFallbackKeyManifest = false;
        return;
      }

      _hasFallbackKeyManifest = true;
      for (final String key in _extractManifestKeys(resolvedFlag!)) {
        _ownedFallbackKeys.add(key);
        if (_fallbackStorage.has(key)) {
          final Map<String, dynamic>? value = _fallbackStorage.get(key);
          if (value != null) {
            _map[_addPrefix(key)] = value;
          }
        }
      }
    } on Object catch (e) {
      _logger.warning('Failed to restore from fallback storage', e);
    }
  }

  /// Copies all current entries (with any pending mutation applied) to
  /// [_fallbackStorage] before persisting [fallbackFlagKey]. If copying any
  /// entry or persisting the marker fails, the exception propagates and the
  /// store remains on secure storage so a subsequent call or relaunch can
  /// retry migration without data loss.
  Future<void> _migrateAndCommitFallback({
    required Object error,
    Map<String, Map<String, dynamic>> extraEntries =
        const <String, Map<String, dynamic>>{},
    Set<String> keysToRemove = const <String>{},
  }) async {
    _logger.warning(
      'Secure storage failed, switching WalletConnect secure store to '
      'fallback storage (${_fallbackStorage.runtimeType})',
      error,
    );

    final Map<String, Map<String, dynamic>> targetEntries =
        <String, Map<String, dynamic>>{};
    for (final MapEntry<String, Map<String, dynamic>> entry in _map.entries) {
      final String unprefixedKey = _removePrefix(entry.key);
      if (!keysToRemove.contains(unprefixedKey)) {
        targetEntries[unprefixedKey] = entry.value;
      }
    }
    targetEntries.addAll(extraEntries);

    for (final MapEntry<String, Map<String, dynamic>> entry
        in targetEntries.entries) {
      await _fallbackStorage.set(entry.key, entry.value);
    }
    for (final String removedKey in keysToRemove) {
      await _fallbackStorage.delete(removedKey);
    }

    final Set<String> nextOwnedKeys = <String>{
      ..._ownedFallbackKeys,
      ...targetEntries.keys,
    }..removeAll(keysToRemove);

    await _persistFallbackFlag(nextOwnedKeys, authoritative: true);

    _useFallbackStorage = true;
    _fallbackPersisted = true;
    _fallbackAuthoritative = true;
    _hasFallbackKeyManifest = true;
    _ownedFallbackKeys
      ..clear()
      ..addAll(nextOwnedKeys);

    for (final String removedKey in keysToRemove) {
      _map.remove(_addPrefix(removedKey));
    }
    for (final MapEntry<String, Map<String, dynamic>> entry
        in extraEntries.entries) {
      _map[_addPrefix(entry.key)] = entry.value;
    }
  }

  Future<void> _persistFallbackFlag(
    Set<String> ownedKeys, {
    required bool authoritative,
  }) async {
    final List<String> sortedKeys = ownedKeys.toList()..sort();
    try {
      await _fallbackStorage.set(fallbackFlagKey, <String, dynamic>{
        'enabled': true,
        _fallbackAuthoritativeField: authoritative,
        _fallbackKeysField: sortedKeys,
      });
    } on Object catch (e, s) {
      _logger.warning('Failed to persist secure storage fallback marker', e, s);
      rethrow;
    }
  }

  String _addPrefix(String key) => '$storagePrefix$key';

  String _removePrefix(String key) =>
      key.startsWith(storagePrefix) ? key.substring(storagePrefix.length) : key;

  void _checkInitialized() {
    if (!_initialized) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getInternalError(Errors.NOT_INITIALIZED);
    }
  }
}
