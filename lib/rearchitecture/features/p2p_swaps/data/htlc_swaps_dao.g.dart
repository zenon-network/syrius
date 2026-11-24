// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'htlc_swaps_dao.dart';

// ignore_for_file: type=lint
mixin _$HtlcSwapsDaoMixin on DatabaseAccessor<HtlcSwapsDatabase> {
  $HtlcSwapEntriesTable get htlcSwapEntries => attachedDatabase.htlcSwapEntries;
  $HtlcScanCheckpointsTable get htlcScanCheckpoints =>
      attachedDatabase.htlcScanCheckpoints;
  HtlcSwapsDaoManager get managers => HtlcSwapsDaoManager(this);
}

class HtlcSwapsDaoManager {
  final _$HtlcSwapsDaoMixin _db;
  HtlcSwapsDaoManager(this._db);
  $$HtlcSwapEntriesTableTableManager get htlcSwapEntries =>
      $$HtlcSwapEntriesTableTableManager(
        _db.attachedDatabase,
        _db.htlcSwapEntries,
      );
  $$HtlcScanCheckpointsTableTableManager get htlcScanCheckpoints =>
      $$HtlcScanCheckpointsTableTableManager(
        _db.attachedDatabase,
        _db.htlcScanCheckpoints,
      );
}
