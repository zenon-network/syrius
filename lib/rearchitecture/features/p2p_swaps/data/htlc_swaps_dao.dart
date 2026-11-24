import 'package:drift/drift.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';

part 'htlc_swaps_dao.g.dart';

@DriftAccessor(tables: <Type>[HtlcSwapEntries, HtlcScanCheckpoints])
/// Provides database access for HTLC swaps and scan checkpoints.
class HtlcSwapsDao extends DatabaseAccessor<HtlcSwapsDatabase>
    with _$HtlcSwapsDaoMixin {
  /// Creates a DAO attached to the given database.
  HtlcSwapsDao(super.attachedDatabase);

  /// Returns all stored swaps ordered by descending start time.
  Future<List<HtlcSwapEntry>> readAllSwapEntries() =>
      (select(htlcSwapEntries)..orderBy(<
            OrderingTerm Function(
              $HtlcSwapEntriesTable,
            )
          >[
            ($HtlcSwapEntriesTable table) => OrderingTerm.desc(table.startTime),
          ]))
          .get();

  /// Watches all stored swaps ordered by descending start time.
  Stream<List<HtlcSwapEntry>> watchAllSwapEntries() =>
      (select(htlcSwapEntries)..orderBy(<
            OrderingTerm Function(
              $HtlcSwapEntriesTable,
            )
          >[
            ($HtlcSwapEntriesTable table) => OrderingTerm.desc(table.startTime),
          ]))
          .watch();

  /// Returns swaps on [chainId] whose state is included in [states].
  Future<List<HtlcSwapEntry>> readSwapEntriesByState(
    int chainId,
    List<String> states,
  ) =>
      (select(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) =>
                table.chainId.equals(chainId) & table.state.isIn(states),
          ))
          .get();

  /// Returns the swap on [chainId] with [hashLock], if one exists.
  Future<HtlcSwapEntry?> readSwapEntryByHashLock(
    int chainId,
    String hashLock,
  ) => _readSingleSwapEntry(
    ($HtlcSwapEntriesTable table) =>
        table.chainId.equals(chainId) & table.hashLock.equals(hashLock),
  );

  /// Returns the swap on [chainId] containing [htlcId], if one exists.
  Future<HtlcSwapEntry?> readSwapEntryByHtlcId(int chainId, String htlcId) =>
      _readSingleSwapEntry(
        ($HtlcSwapEntriesTable table) =>
            table.chainId.equals(chainId) &
            (table.initialHtlcId.equals(htlcId) |
                table.counterHtlcId.equals(htlcId)),
      );

  /// Returns the swap identified by [id], if one exists.
  Future<HtlcSwapEntry?> readSwapEntryById(String id) => _readSingleSwapEntry(
    ($HtlcSwapEntriesTable table) => table.id.equals(id),
  );

  /// Returns the last scanned HTLC block height for [chainId], or zero.
  Future<int> readLastCheckedHtlcBlockHeight(int chainId) async {
    final HtlcScanCheckpoint? checkpoint =
        await (select(htlcScanCheckpoints)..where(
              ($HtlcScanCheckpointsTable table) =>
                  table.chainId.equals(chainId),
            ))
            .getSingleOrNull();
    return checkpoint?.lastCheckedHeight ?? 0;
  }

  /// Stores [entry] and prunes eligible history beyond [maximumStoredSwaps].
  Future<void> writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) => transaction(
    () => _writeSwapEntry(
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
  }) => transaction(() async {
    if (updatedEntry != null) {
      if (updatedEntry.chainId != chainId) {
        throw StateError(
          'Cannot store an HTLC swap update for a different chain',
        );
      }
      await _writeSwapEntry(
        updatedEntry,
        maximumStoredSwaps: maximumStoredSwaps,
        pruneChainId: chainId,
        prunableStates: prunableStates,
      );
    }
    await _writeLastCheckedHtlcBlockHeight(chainId, height);
  });

  /// Stores [height] as the last scanned HTLC block for [chainId].
  Future<void> writeLastCheckedHtlcBlockHeight(int chainId, int height) =>
      _writeLastCheckedHtlcBlockHeight(chainId, height);

  /// Atomically inserts swap [entries] whose ids do not already exist,
  /// without overwriting existing rows or pruning history.
  Future<void> insertMissingSwapEntries(List<HtlcSwapEntry> entries) async {
    if (entries.isEmpty) {
      return;
    }

    await transaction(() async {
      await batch((Batch batch) {
        batch.insertAll(
          htlcSwapEntries,
          entries,
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }

  /// Deletes the swap identified by [swapId].
  Future<void> deleteSwapEntry(String swapId) =>
      (delete(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) => table.id.equals(swapId),
          ))
          .go();

  /// Deletes swaps on [chainId] whose state is included in [states].
  Future<void> deleteSwapEntriesByState(
    int chainId,
    List<String> states,
  ) =>
      (delete(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) =>
                table.chainId.equals(chainId) & table.state.isIn(states),
          ))
          .go();

  Future<HtlcSwapEntry?> _readSingleSwapEntry(
    Expression<bool> Function($HtlcSwapEntriesTable table) predicate,
  ) =>
      (select(htlcSwapEntries)
            ..where(predicate)
            ..limit(1))
          .getSingleOrNull();

  Future<void> _writeSwapEntry(
    HtlcSwapEntry entry, {
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) async {
    await into(htlcSwapEntries).insertOnConflictUpdate(entry);
    await _pruneSwapHistoryIfNeeded(
      maximumStoredSwaps: maximumStoredSwaps,
      pruneChainId: pruneChainId,
      prunableStates: prunableStates,
    );
  }

  Future<void> _writeLastCheckedHtlcBlockHeight(
    int chainId,
    int height,
  ) => into(htlcScanCheckpoints).insertOnConflictUpdate(
    HtlcScanCheckpointsCompanion.insert(
      chainId: Value<int>(chainId),
      lastCheckedHeight: height,
    ),
  );

  Future<void> _pruneSwapHistoryIfNeeded({
    required int maximumStoredSwaps,
    required int? pruneChainId,
    required List<String> prunableStates,
  }) async {
    final Expression<int> count = htlcSwapEntries.id.count();
    final TypedResult countResult = await (selectOnly(
      htlcSwapEntries,
    )..addColumns(<Expression<Object>>[count])).getSingle();
    if ((countResult.read(count) ?? 0) <= maximumStoredSwaps ||
        pruneChainId == null) {
      return;
    }

    final HtlcSwapEntry? oldest =
        await (select(htlcSwapEntries)
              ..where(
                ($HtlcSwapEntriesTable table) =>
                    table.chainId.equals(pruneChainId) &
                    table.state.isIn(prunableStates),
              )
              ..orderBy(<OrderingTerm Function($HtlcSwapEntriesTable)>[
                ($HtlcSwapEntriesTable table) =>
                    OrderingTerm.asc(table.startTime),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (oldest != null) {
      await (delete(htlcSwapEntries)..where(
            ($HtlcSwapEntriesTable table) => table.id.equals(oldest.id),
          ))
          .go();
    }
  }
}
