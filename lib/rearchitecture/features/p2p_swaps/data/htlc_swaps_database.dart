import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hex/hex.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_dao.dart';

part 'htlc_swaps_database.g.dart';

@TableIndex(name: 'htlc_swaps_chain_state', columns: <Symbol>{#chainId, #state})
@TableIndex(name: 'htlc_swaps_hash_lock', columns: <Symbol>{#hashLock})
@TableIndex(
  name: 'htlc_swaps_initial_htlc_id',
  columns: <Symbol>{#initialHtlcId},
)
@TableIndex(
  name: 'htlc_swaps_counter_htlc_id',
  columns: <Symbol>{#counterHtlcId},
)
@TableIndex(
  name: 'htlc_swaps_chain_start_time',
  columns: <Symbol>{#chainId, #startTime},
)
/// Defines the persisted HTLC swap records.
class HtlcSwapEntries extends Table {
  /// The unique swap identifier.
  TextColumn get id => text()();

  /// The identifier of the chain containing the swap.
  IntColumn get chainId => integer()();

  /// The serialized swap lifecycle state.
  TextColumn get state => text()();

  /// The serialized swap direction.
  TextColumn get direction => text()();

  /// The swap's hash lock.
  TextColumn get hashLock => text()();

  /// The identifier of the initial HTLC.
  TextColumn get initialHtlcId => text()();

  /// The identifier of the counterparty HTLC, when available.
  TextColumn get counterHtlcId => text().nullable()();

  /// The swap start time.
  IntColumn get startTime => integer()();

  /// The complete serialized swap payload.
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  String get tableName => 'htlc_swaps';
}

/// Defines the last scanned HTLC block for each chain.
class HtlcScanCheckpoints extends Table {
  /// The identifier of the scanned chain.
  IntColumn get chainId => integer()();

  /// The last block height checked for HTLC updates.
  IntColumn get lastCheckedHeight => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{chainId};
}

@DriftDatabase(
  tables: <Type>[HtlcSwapEntries, HtlcScanCheckpoints],
  daos: <Type>[HtlcSwapsDao],
)
/// Stores HTLC swaps in an encrypted Drift database.
class HtlcSwapsDatabase extends _$HtlcSwapsDatabase {
  /// Creates a database using [executor].
  HtlcSwapsDatabase(super.e);

  /// Creates a database at [file] encrypted with [encryptionKey].
  factory HtlcSwapsDatabase.encrypted(File file, List<int> encryptionKey) {
    if (encryptionKey.length != 32 ||
        encryptionKey.any((int byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(
        encryptionKey,
        'encryptionKey',
        'The database encryption key must contain exactly 32 bytes',
      );
    }

    final String keyHex = HEX.encode(encryptionKey);
    return HtlcSwapsDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (Database database) {
          if (database.select('PRAGMA cipher;').isEmpty) {
            throw UnsupportedError(
              'SQLite3MultipleCiphers is required for HTLC swap storage',
            );
          }

          database
            ..execute("PRAGMA cipher = 'sqlcipher';")
            ..execute('PRAGMA legacy = 4;')
            ..execute("PRAGMA hexkey = '$keyHex';")
            ..select('SELECT count(*) FROM sqlite_master;');
        },
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  /// Verifies that the encrypted database can be queried.
  Future<void> verifyOpen() async {
    await customSelect('SELECT count(*) FROM sqlite_master;').getSingle();
  }

  /// Re-encrypts the database with [encryptionKey].
  Future<void> rekey(List<int> encryptionKey) async {
    if (encryptionKey.length != 32 ||
        encryptionKey.any((int byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(
        encryptionKey,
        'encryptionKey',
        'The database encryption key must contain exactly 32 bytes',
      );
    }

    await customStatement(
      "PRAGMA hexrekey = '${HEX.encode(encryptionKey)}';",
    );
  }
}
