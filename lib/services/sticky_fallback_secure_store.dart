import 'dart:async';
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
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(resetOnError: false),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  /// Marker persisted in [_fallbackStorage] once fallback storage becomes
  /// authoritative, including the manifest of unprefixed keys owned by this
  /// store so subsequent launches restore and delete only secure-store entries
  /// without touching unrelated keys sharing [_fallbackStorage].
  static const String fallbackFlagKey = 'secure_store_fallback_mode';

  static const String _fallbackKeysField = 'keys';
  static const String _fallbackAuthoritativeField = 'authoritative';
  static const String _fallbackDeletedKeysField = 'deletedKeys';
  static const String _fallbackReplacedKeysField = 'replacedKeys';
  static const String _fallbackClearedAllField = 'clearedAll';

  final Logger _logger = Logger('StickyFallbackSecureStore');
  final FlutterSecureStorage _secureStorage;
  final IStore<Map<String, dynamic>> _fallbackStorage;
  final Map<String, Map<String, dynamic>> _map;
  final Set<String> _ownedFallbackKeys = <String>{};
  final Set<String> _transientDeletedKeys = <String>{};
  final Set<String> _transientReplacedKeys = <String>{};

  Future<void> _mutationQueue = Future<void>.value();
  bool _initialized = false;
  bool _useFallbackStorage = false;
  bool _fallbackPersisted = false;
  bool _fallbackAuthoritative = false;
  bool _hasFallbackKeyManifest = false;
  bool _isLegacyFallbackMarker = false;
  bool _transientClearedAll = false;

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

  /// Serializes async store mutations so concurrent `set`, `update`, `delete`,
  /// `deleteAll`, and fallback migrations cannot interleave stale snapshots.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final Completer<T> completer = Completer<T>();
    _mutationQueue = _mutationQueue.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  @override
  Future<void> init() => _synchronized(_initLocked);

  Future<void> _initLocked() async {
    if (_initialized) {
      return;
    }

    Map<String, dynamic>? existingFlag;
    if (_fallbackStorage.has(fallbackFlagKey)) {
      try {
        existingFlag = _fallbackStorage.get(fallbackFlagKey);
      } on Object catch (e, s) {
        _logger.warning(
          'Fallback storage marker exists but could not be read',
          e,
          s,
        );
        rethrow;
      }
      if (existingFlag == null) {
        throw StateError('Fallback storage marker exists but returned null');
      }
    }

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

    bool secureReadSucceeded = false;
    try {
      await _restoreFromSecureStorage();
      secureReadSucceeded = true;
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

    if (secureReadSucceeded && existingFlag != null) {
      final List<String> transientKeys = _extractStringListField(
        existingFlag,
        _fallbackKeysField,
      );
      final List<String> deletedKeys = _extractStringListField(
        existingFlag,
        _fallbackDeletedKeysField,
      );
      final List<String> replacedKeys = _extractStringListField(
        existingFlag,
        _fallbackReplacedKeysField,
      );
      final bool clearedAll =
          (existingFlag[_fallbackClearedAllField] as bool?) ?? false;
      final bool keychainHadEntries = _map.isNotEmpty;

      if (keychainHadEntries ||
          clearedAll ||
          deletedKeys.isNotEmpty ||
          replacedKeys.isNotEmpty) {
        await _reconcileTransientFallbackIntoSecureStorage(
          transientKeys: transientKeys,
          deletedKeys: deletedKeys,
          replacedKeys: replacedKeys,
          clearedAll: clearedAll,
        );
      } else if (transientKeys.isNotEmpty) {
        // Keychain succeeded empty while a prior transient fallback holds
        // persisted data (e.g., first launch failed readAll and wrote new
        // session keys): restore those fallback entries instead of dropping
        // them, while keeping `authoritative: false` unless writes fail.
        _useFallbackStorage = true;
        _fallbackPersisted = true;
        _fallbackAuthoritative = false;
        await _restoreFromFallback(flagData: existingFlag);
      } else {
        await _clearTransientFallbackData(
          transientKeys,
          rethrowOnMarkerDeleteFailure: false,
        );
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
  Future<void> set(String key, Map<String, dynamic> value) {
    _checkInitialized();
    return _synchronized(() => _persistEntryLocked(key, value));
  }

  @override
  Future<void> update(String key, Map<String, dynamic> value) {
    _checkInitialized();
    return _synchronized(() async {
      if (!has(key)) {
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw Errors.getInternalError(Errors.NO_MATCHING_KEY);
      }
      await _persistEntryLocked(key, value);
    });
  }

  Future<void> _persistEntryLocked(
    String key,
    Map<String, dynamic> value,
  ) async {
    final String keyWithPrefix = _addPrefix(key);

    if (_useFallbackStorage) {
      // Use set() rather than update() so a cold SharedPrefsStores instance
      // whose in-memory map hasn't been hydrated yet still persists cleanly.
      await _fallbackStorage.set(key, value);

      final Set<String> nextOwnedKeys = Set<String>.from(_ownedFallbackKeys)
        ..add(key);
      final bool recreatedAfterDeletion =
          !_fallbackAuthoritative && _transientDeletedKeys.contains(key);
      final Set<String> nextDeletedKeys = Set<String>.from(
        _transientDeletedKeys,
      )..remove(key);
      final Set<String> nextReplacedKeys = Set<String>.from(
        _transientReplacedKeys,
      );
      if (recreatedAfterDeletion) {
        nextReplacedKeys.add(key);
      }

      if (!_isLegacyFallbackMarker) {
        final bool needsFlagWrite =
            !_fallbackPersisted ||
            !_hasFallbackKeyManifest ||
            !_ownedFallbackKeys.contains(key) ||
            _transientDeletedKeys.contains(key) ||
            nextReplacedKeys.length != _transientReplacedKeys.length;
        if (needsFlagWrite) {
          await _persistFallbackFlag(
            nextOwnedKeys,
            authoritative: _fallbackAuthoritative,
            deletedKeys: nextDeletedKeys,
            replacedKeys: nextReplacedKeys,
            clearedAll: _transientClearedAll,
          );
          _fallbackPersisted = true;
          _hasFallbackKeyManifest = true;
        }
      }

      _ownedFallbackKeys.add(key);
      _transientDeletedKeys.remove(key);
      if (recreatedAfterDeletion) {
        _transientReplacedKeys.add(key);
      }
      _map[keyWithPrefix] = value;
      return;
    }

    try {
      await _secureStorage.write(key: keyWithPrefix, value: jsonEncode(value));
      _map[keyWithPrefix] = value;
    } on Object catch (e) {
      await _migrateAndCommitFallbackLocked(
        error: e,
        extraEntries: <String, Map<String, dynamic>>{key: value},
      );
    }
  }

  @override
  Future<void> delete(String key) {
    _checkInitialized();
    return _synchronized(() => _deleteLocked(key));
  }

  Future<void> _deleteLocked(String key) async {
    if (key == fallbackFlagKey) {
      return;
    }

    final String keyWithPrefix = _addPrefix(key);

    if (_useFallbackStorage) {
      final bool ownsFallbackKey =
          !_hasFallbackKeyManifest || _ownedFallbackKeys.contains(key);
      if (!ownsFallbackKey && _fallbackAuthoritative) {
        _map.remove(keyWithPrefix);
        return;
      }

      if (ownsFallbackKey) {
        await _fallbackStorage.delete(key);
      }

      final Set<String> nextOwnedKeys = Set<String>.from(_ownedFallbackKeys)
        ..remove(key);
      final Set<String> nextDeletedKeys = Set<String>.from(
        _transientDeletedKeys,
      );
      final Set<String> nextReplacedKeys = Set<String>.from(
        _transientReplacedKeys,
      )..remove(key);
      if (!_fallbackAuthoritative) {
        nextDeletedKeys.add(key);
      }

      if (!_isLegacyFallbackMarker) {
        final bool needsFlagWrite =
            !_fallbackPersisted ||
            !_hasFallbackKeyManifest ||
            _ownedFallbackKeys.contains(key) ||
            _transientReplacedKeys.contains(key) ||
            !_fallbackAuthoritative;
        if (needsFlagWrite) {
          await _persistFallbackFlag(
            nextOwnedKeys,
            authoritative: _fallbackAuthoritative,
            deletedKeys: nextDeletedKeys,
            replacedKeys: nextReplacedKeys,
            clearedAll: _transientClearedAll,
          );
          _fallbackPersisted = true;
          _hasFallbackKeyManifest = true;
        }
      }

      _ownedFallbackKeys.remove(key);
      if (!_fallbackAuthoritative) {
        _transientDeletedKeys.add(key);
        _transientReplacedKeys.remove(key);
      }
      _map.remove(keyWithPrefix);
      return;
    }

    try {
      await _secureStorage.delete(key: keyWithPrefix);
      _map.remove(keyWithPrefix);
    } on Object catch (e, s) {
      _logger.warning('Failed to delete key $key from secure storage', e, s);
      rethrow;
    }
  }

  @override
  Future<void> deleteAll() {
    _checkInitialized();
    return _synchronized(_deleteAllLocked);
  }

  Future<void> _deleteAllLocked() async {
    if (_useFallbackStorage) {
      final Set<String> keysToDelete = <String>{
        ..._ownedFallbackKeys,
        ..._map.keys.map(_removePrefix),
      }..remove(fallbackFlagKey);
      for (final String unprefixedKey in keysToDelete) {
        await _fallbackStorage.delete(unprefixedKey);
      }

      if (_fallbackAuthoritative) {
        await _persistFallbackFlag(const <String>{}, authoritative: true);
        _fallbackPersisted = true;
        _isLegacyFallbackMarker = false;
        _transientReplacedKeys.clear();
      } else {
        await _persistFallbackFlag(
          const <String>{},
          authoritative: false,
          clearedAll: true,
        );
        _fallbackPersisted = true;
        _transientClearedAll = true;
        _transientDeletedKeys.clear();
        _transientReplacedKeys.clear();
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
          _map.remove(key);
        }
      }
      _map.clear();
    } on Object catch (e, s) {
      _logger.warning('Failed to delete all entries from secure storage', e, s);
      rethrow;
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
        // Omit the exception object/source text so decrypted key material
        // inside malformed JSON cannot be written to application logs.
        _logger.warning(
          'Failed to decode secure storage value for key '
          '${entry.key} (${e.runtimeType})',
        );
      }
    }
  }

  List<String> _extractStringListField(
    Map<String, dynamic> flagData,
    String fieldName,
  ) {
    final Object? rawList = flagData[fieldName];
    if (rawList is! List) {
      return const <String>[];
    }
    return rawList
        .whereType<String>()
        .where((String key) => key.isNotEmpty && key != fallbackFlagKey)
        .toList();
  }

  Future<void> _reconcileTransientFallbackIntoSecureStorage({
    required List<String> transientKeys,
    required List<String> deletedKeys,
    required List<String> replacedKeys,
    required bool clearedAll,
  }) async {
    // 1. Compute the fully reconciled state in memory first so any subsequent
    // OS keychain write/delete failure can cleanly promote the reconciled view
    // (preserving both OS entries and transient writes while honoring
    // tombstones and bucket replacements) into authoritative fallback storage.
    final Map<String, Map<String, dynamic>> reconciledMap =
        <String, Map<String, dynamic>>{
          for (final MapEntry<String, Map<String, dynamic>> entry
              in _map.entries)
            entry.key: Map<String, dynamic>.from(entry.value),
        };
    final List<String> osKeysToDelete = <String>[];
    final Map<String, Map<String, dynamic>> osEntriesToWrite =
        <String, Map<String, dynamic>>{};
    final Set<String> replacedKeySet = replacedKeys.toSet();

    if (clearedAll) {
      osKeysToDelete.addAll(reconciledMap.keys);
      reconciledMap.clear();
    } else {
      for (final String deletedKey in deletedKeys) {
        final String prefixedKey = _addPrefix(deletedKey);
        if (reconciledMap.containsKey(prefixedKey)) {
          osKeysToDelete.add(prefixedKey);
          reconciledMap.remove(prefixedKey);
        }
      }
    }

    for (final String transientKey in transientKeys) {
      Map<String, dynamic>? transientValue;
      try {
        if (!_fallbackStorage.has(transientKey)) {
          continue;
        }
        transientValue = _fallbackStorage.get(transientKey);
      } on Object catch (e) {
        // Omit exception details that could contain raw serialized values
        // (CWE-532), and abort before any OS mutations or cleanup so the
        // marker and transient fallback copy remain recoverable on retry.
        _logger.warning(
          'Failed to read transient fallback entry $transientKey during '
          'reconciliation (${e.runtimeType})',
        );
        rethrow;
      }
      if (transientValue == null) {
        continue;
      }
      final String prefixedKey = _addPrefix(transientKey);
      final Map<String, dynamic>? existingValue = reconciledMap[prefixedKey];
      if (existingValue == null || replacedKeySet.contains(transientKey)) {
        final Map<String, dynamic> copy = Map<String, dynamic>.from(
          transientValue,
        );
        reconciledMap[prefixedKey] = copy;
        osEntriesToWrite[prefixedKey] = copy;
      } else {
        final Map<String, dynamic> merged = Map<String, dynamic>.from(
          existingValue,
        );
        bool addedEntries = false;
        for (final MapEntry<String, dynamic> subEntry
            in transientValue.entries) {
          if (!merged.containsKey(subEntry.key)) {
            merged[subEntry.key] = subEntry.value;
            addedEntries = true;
          }
        }
        if (addedEntries) {
          reconciledMap[prefixedKey] = merged;
          osEntriesToWrite[prefixedKey] = merged;
        }
      }
    }

    // 2. Apply deletes and merged writes to the OS keychain.
    try {
      for (final String prefixedKey in osKeysToDelete) {
        await _secureStorage.delete(key: prefixedKey);
      }
      for (final MapEntry<String, Map<String, dynamic>> entry
          in osEntriesToWrite.entries) {
        await _secureStorage.write(
          key: entry.key,
          value: jsonEncode(entry.value),
        );
      }
    } on Object catch (writeError) {
      // OS keychain reads worked, but writes/deletes are denied: commit the
      // complete reconciled state into authoritative fallback storage before
      // removing any stale transient copies.
      await _migrateAndCommitFallbackLocked(
        error: writeError,
        replacementMap: reconciledMap,
      );
      final Set<String> reconciledUnprefixedKeys = reconciledMap.keys
          .map(_removePrefix)
          .toSet();
      for (final String staleKey in transientKeys) {
        if (!reconciledUnprefixedKeys.contains(staleKey) &&
            staleKey != fallbackFlagKey) {
          try {
            await _fallbackStorage.delete(staleKey);
          } on Object {
            // Best-effort cleanup of stale transient entries after the
            // authoritative marker has already been committed.
          }
        }
      }
      return;
    }

    // 3. OS reconciliation succeeded: durably retire the reset/transient marker
    // BEFORE deleting transient fallback copies so a failed marker deletion or
    // mid-cleanup exit can never replay `clearedAll` after losing the copies.
    await _clearTransientFallbackData(transientKeys);
    _map
      ..clear()
      ..addAll(reconciledMap);
    _transientClearedAll = false;
    _transientDeletedKeys.clear();
    _transientReplacedKeys.clear();
  }

  Future<void> _clearTransientFallbackData(
    List<String> transientKeys, {
    bool rethrowOnMarkerDeleteFailure = true,
  }) async {
    try {
      await _fallbackStorage.delete(fallbackFlagKey);
    } on Object catch (e, s) {
      _logger.warning(
        'Failed to retire transient secure storage fallback marker',
        e,
        s,
      );
      if (rethrowOnMarkerDeleteFailure) {
        rethrow;
      }
      return;
    }

    for (final String key in transientKeys) {
      try {
        await _fallbackStorage.delete(key);
      } on Object catch (e, s) {
        _logger.warning(
          'Failed to clean up transient fallback entry $key',
          e,
          s,
        );
      }
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
        // Legacy fallback flag without an explicit key manifest: keep lazy
        // lookup enabled until deleteAll() resets the store so unread legacy
        // entries are never hidden.
        _hasFallbackKeyManifest = false;
        _isLegacyFallbackMarker = true;
        return;
      }

      _hasFallbackKeyManifest = true;
      _isLegacyFallbackMarker = false;
      _transientClearedAll =
          (resolvedFlag![_fallbackClearedAllField] as bool?) ?? false;
      _transientDeletedKeys
        ..clear()
        ..addAll(
          _extractStringListField(resolvedFlag, _fallbackDeletedKeysField),
        );
      _transientReplacedKeys
        ..clear()
        ..addAll(
          _extractStringListField(resolvedFlag, _fallbackReplacedKeysField),
        );

      // Register the entire manifest in _ownedFallbackKeys before reading any
      // value so a per-entry read error cannot drop later keys from ownership.
      final List<String> manifestKeys = _extractStringListField(
        resolvedFlag,
        _fallbackKeysField,
      );
      _ownedFallbackKeys
        ..clear()
        ..addAll(manifestKeys);

      for (final String key in manifestKeys) {
        try {
          if (_fallbackStorage.has(key)) {
            final Map<String, dynamic>? value = _fallbackStorage.get(key);
            if (value != null) {
              _map[_addPrefix(key)] = value;
            }
          }
        } on Object catch (e) {
          // Omit exception details that could contain raw serialized values
          // (CWE-532), while keeping the key in _ownedFallbackKeys so later
          // writes do not evict it.
          _logger.warning(
            'Failed to restore fallback storage entry for key $key '
            '(${e.runtimeType})',
          );
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
  Future<void> _migrateAndCommitFallbackLocked({
    required Object error,
    Map<String, Map<String, dynamic>> extraEntries =
        const <String, Map<String, dynamic>>{},
    Map<String, Map<String, dynamic>>? replacementMap,
  }) async {
    _logger.warning(
      'Secure storage failed, switching WalletConnect secure store to '
      'fallback storage (${_fallbackStorage.runtimeType})',
      error,
    );

    final Map<String, Map<String, dynamic>> sourceMap = replacementMap ?? _map;
    final Map<String, Map<String, dynamic>> targetEntries =
        <String, Map<String, dynamic>>{
          for (final MapEntry<String, Map<String, dynamic>> entry
              in sourceMap.entries)
            _removePrefix(entry.key): entry.value,
          ...extraEntries,
        };

    for (final MapEntry<String, Map<String, dynamic>> entry
        in targetEntries.entries) {
      await _fallbackStorage.set(entry.key, entry.value);
    }

    final Set<String> nextOwnedKeys = replacementMap != null
        ? Set<String>.from(targetEntries.keys)
        : <String>{..._ownedFallbackKeys, ...targetEntries.keys};

    await _persistFallbackFlag(nextOwnedKeys, authoritative: true);

    if (replacementMap != null) {
      _map
        ..clear()
        ..addAll(replacementMap);
    }
    _useFallbackStorage = true;
    _fallbackPersisted = true;
    _fallbackAuthoritative = true;
    _hasFallbackKeyManifest = true;
    _isLegacyFallbackMarker = false;
    _transientClearedAll = false;
    _transientDeletedKeys.clear();
    _transientReplacedKeys.clear();
    _ownedFallbackKeys
      ..clear()
      ..addAll(nextOwnedKeys);

    for (final MapEntry<String, Map<String, dynamic>> entry
        in extraEntries.entries) {
      _map[_addPrefix(entry.key)] = entry.value;
    }
  }

  Future<void> _persistFallbackFlag(
    Set<String> ownedKeys, {
    required bool authoritative,
    Set<String> deletedKeys = const <String>{},
    Set<String> replacedKeys = const <String>{},
    bool clearedAll = false,
  }) async {
    final List<String> sortedKeys = ownedKeys.toList()..sort();
    final Map<String, dynamic> payload = <String, dynamic>{
      'enabled': true,
      _fallbackAuthoritativeField: authoritative,
      _fallbackKeysField: sortedKeys,
      if (!authoritative && deletedKeys.isNotEmpty)
        _fallbackDeletedKeysField: (deletedKeys.toList()..sort()),
      if (!authoritative && replacedKeys.isNotEmpty)
        _fallbackReplacedKeysField: (replacedKeys.toList()..sort()),
      if (!authoritative && clearedAll) _fallbackClearedAllField: true,
    };
    try {
      await _fallbackStorage.set(fallbackFlagKey, payload);
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
