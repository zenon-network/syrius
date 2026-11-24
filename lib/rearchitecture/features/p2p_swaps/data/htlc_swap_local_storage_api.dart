import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_dao.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Provides encrypted local storage for HTLC swap data.
class HtlcSwapLocalStorageApi {
  /// Creates storage backed by [databaseFile] or the default cache database.
  HtlcSwapLocalStorageApi({File? databaseFile})
    : _storageFile =
          databaseFile ??
          File(path.join(znnDefaultPaths.cache.path, kHtlcSwapsDatabase));

  final File _storageFile;
  final Mutex _mutex = Mutex();

  HtlcSwapsDatabase? _connection;

  File get _rekeyBackupFile => File('${_storageFile.path}.rekey-backup');

  /// Opens the database with [encryptionKey], recovering a rekey backup if
  /// needed.
  Future<void> open(List<int> encryptionKey) => _mutex.protect(() async {
    if (_connection != null) {
      return;
    }

    await _storageFile.parent.create(recursive: true);
    try {
      _connection = await _openConnection(_storageFile, encryptionKey);
    } catch (_) {
      if (!_rekeyBackupFile.existsSync()) {
        rethrow;
      }

      final HtlcSwapsDatabase backupConnection = await _openConnection(
        _rekeyBackupFile,
        encryptionKey,
      );
      await backupConnection.close();
      await _deleteSqliteFiles(_storageFile);
      await _rekeyBackupFile.rename(_storageFile.path);
      _connection = await _openConnection(_storageFile, encryptionKey);
    }

    try {
      await _deleteSqliteFiles(_rekeyBackupFile);
    } on FileSystemException {
      // A valid primary database makes a stale encrypted backup disposable.
    }
  });

  /// Closes the database connection.
  Future<void> close() => _mutex.protect(_closeConnection);

  /// Closes and deletes the database and any rekey backup.
  Future<void> deleteDatabase() => _mutex.protect(() async {
    await _closeConnection();
    await _deleteSqliteFiles(_storageFile);
    await _deleteSqliteFiles(_rekeyBackupFile);
  });

  /// Re-encrypts the database while retaining a rollback backup.
  Future<void> beginRekey({
    required List<int> oldEncryptionKey,
    required List<int> newEncryptionKey,
  }) => _mutex.protect(() async {
    final HtlcSwapsDatabase connection = _requireConnection();
    await connection.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    await _closeConnection();
    await _deleteSqliteFiles(_rekeyBackupFile);
    await _storageFile.copy(_rekeyBackupFile.path);

    try {
      _connection = await _openConnection(_storageFile, oldEncryptionKey);
      await _connection!.rekey(newEncryptionKey);
      await _closeConnection();
      _connection = await _openConnection(_storageFile, newEncryptionKey);
    } catch (_) {
      await _restoreRekeyBackup(oldEncryptionKey);
      rethrow;
    }
  });

  /// Commits a completed rekey by deleting its backup.
  Future<void> commitRekey() => _mutex.protect(() async {
    try {
      await _deleteSqliteFiles(_rekeyBackupFile);
    } on FileSystemException {
      // A stale encrypted backup is removed the next time the database opens.
    }
  });

  /// Restores the rekey backup using [oldEncryptionKey].
  Future<void> rollbackRekey(List<int> oldEncryptionKey) =>
      _mutex.protect(() => _restoreRekeyBackup(oldEncryptionKey));

  /// Returns all stored swaps ordered by descending start time.
  Future<List<HtlcSwapEntry>> readAllSwapEntries() =>
      _withDao((HtlcSwapsDao dao) => dao.readAllSwapEntries());

  /// Watches all stored swaps ordered by descending start time.
  Stream<List<HtlcSwapEntry>> watchAllSwapEntries() =>
      _requireConnection().htlcSwapsDao.watchAllSwapEntries();

  /// Returns swaps on [chainId] whose state is included in [states].
  Future<List<HtlcSwapEntry>> readSwapEntriesByState(
    int chainId,
    List<String> states,
  ) => _withDao(
    (HtlcSwapsDao dao) => dao.readSwapEntriesByState(chainId, states),
  );

  /// Returns the swap on [chainId] with [hashLock], if one exists.
  Future<HtlcSwapEntry?> readSwapEntryByHashLock(
    int chainId,
    String hashLock,
  ) => _withDao(
    (HtlcSwapsDao dao) => dao.readSwapEntryByHashLock(chainId, hashLock),
  );

  /// Returns the swap on [chainId] containing [htlcId], if one exists.
  Future<HtlcSwapEntry?> readSwapEntryByHtlcId(int chainId, String htlcId) =>
      _withDao(
        (HtlcSwapsDao dao) => dao.readSwapEntryByHtlcId(chainId, htlcId),
      );

  /// Returns the swap identified by [id], if one exists.
  Future<HtlcSwapEntry?> readSwapEntryById(String id) => _withDao(
    (HtlcSwapsDao dao) => dao.readSwapEntryById(id),
  );

  /// Returns the last scanned HTLC block height for [chainId].
  Future<int> readLastCheckedHtlcBlockHeight(int chainId) => _withDao(
    (HtlcSwapsDao dao) => dao.readLastCheckedHtlcBlockHeight(chainId),
  );

  /// Stores [entry] and prunes eligible history beyond [maximumStoredSwaps].
  Future<void> writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) => _withDao(
    (HtlcSwapsDao dao) => dao.writeSwapEntry(
      entry,
      maximumStoredSwaps: maximumStoredSwaps,
      pruneChainId: pruneChainId,
      prunableStates: prunableStates,
    ),
  );

  /// Atomically stores a processed block checkpoint and optional swap update.
  Future<void> writeProcessedHtlcBlock({
    required int chainId,
    required int height,
    required HtlcSwapEntry? updatedEntry,
    required int maximumStoredSwaps,
    required List<String> prunableStates,
  }) => _withDao(
    (HtlcSwapsDao dao) => dao.writeProcessedHtlcBlock(
      chainId: chainId,
      height: height,
      updatedEntry: updatedEntry,
      maximumStoredSwaps: maximumStoredSwaps,
      prunableStates: prunableStates,
    ),
  );

  /// Stores [height] as the last scanned HTLC block for [chainId].
  Future<void> writeLastCheckedHtlcBlockHeight(int chainId, int height) =>
      _withDao(
        (HtlcSwapsDao dao) =>
            dao.writeLastCheckedHtlcBlockHeight(chainId, height),
      );

  /// Atomically inserts swap [entries] whose ids are not yet stored, without
  /// overwriting existing rows or pruning history.
  Future<void> insertMissingSwapEntries(List<HtlcSwapEntry> entries) =>
      _withDao((HtlcSwapsDao dao) => dao.insertMissingSwapEntries(entries));

  /// Deletes the swap identified by [swapId].
  Future<void> deleteSwapEntry(String swapId) =>
      _withDao((HtlcSwapsDao dao) => dao.deleteSwapEntry(swapId));

  /// Deletes swaps on [chainId] whose state is included in [states].
  Future<void> deleteSwapEntriesByState(
    int chainId,
    List<String> states,
  ) => _withDao(
    (HtlcSwapsDao dao) => dao.deleteSwapEntriesByState(chainId, states),
  );

  Future<T> _withDao<T>(
    Future<T> Function(HtlcSwapsDao dao) operation,
  ) => _mutex.protect(
    () => operation(_requireConnection().htlcSwapsDao),
  );

  HtlcSwapsDatabase _requireConnection() {
    return _connection ??
        (throw StateError('The HTLC swaps database is not open'));
  }

  Future<HtlcSwapsDatabase> _openConnection(
    File file,
    List<int> encryptionKey,
  ) async {
    final HtlcSwapsDatabase connection = HtlcSwapsDatabase.encrypted(
      file,
      encryptionKey,
    );
    try {
      await connection.verifyOpen();
      return connection;
    } catch (_) {
      await connection.close();
      rethrow;
    }
  }

  Future<void> _closeConnection() async {
    final HtlcSwapsDatabase? connection = _connection;
    _connection = null;
    await connection?.close();
  }

  Future<void> _restoreRekeyBackup(List<int> oldEncryptionKey) async {
    await _closeConnection();
    if (!_rekeyBackupFile.existsSync()) {
      throw StateError('The HTLC swaps rekey backup does not exist');
    }

    await _deleteSqliteFiles(_storageFile);
    await _rekeyBackupFile.rename(_storageFile.path);
    _connection = await _openConnection(_storageFile, oldEncryptionKey);
  }

  Future<void> _deleteSqliteFiles(File storageFile) async {
    for (final String suffix in <String>['', '-wal', '-shm']) {
      final File file = File('${storageFile.path}$suffix');
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}
