import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_dao.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';

void main() {
  late HtlcSwapsDatabase database;
  late HtlcSwapsDao dao;

  setUp(() {
    database = HtlcSwapsDatabase(NativeDatabase.memory());
    dao = database.htlcSwapsDao;
  });

  tearDown(() => database.close());

  test('reads all swap entries and chain-scoped operational data', () async {
    final HtlcSwapEntry first = _buildEntry(id: 'first', startTime: 3);
    final HtlcSwapEntry second = _buildEntry(
      id: 'second',
      state: 'completed',
      startTime: 2,
    );
    final HtlcSwapEntry otherChain = _buildEntry(
      id: 'other-chain',
      chainId: 2,
    );
    await _writeEntries(dao, <HtlcSwapEntry>[first, second, otherChain]);

    expect(
      await dao.readAllSwapEntries(),
      <HtlcSwapEntry>[first, second, otherChain],
    );
    expect(
      await dao.readSwapEntriesByState(1, <String>['completed']),
      <HtlcSwapEntry>[second],
    );
    expect(await dao.readSwapEntryById(first.id), first);
    expect(await dao.readSwapEntryByHashLock(1, first.hashLock), first);
    expect(await dao.readSwapEntryByHtlcId(1, first.initialHtlcId), first);
    expect(await dao.readSwapEntryByHtlcId(1, first.counterHtlcId!), first);
  });

  test('watches all swap entries ordered newest first', () async {
    final StreamIterator<List<HtlcSwapEntry>> entries =
        StreamIterator<List<HtlcSwapEntry>>(
          dao.watchAllSwapEntries(),
        );
    addTearDown(entries.cancel);

    expect(await entries.moveNext(), isTrue);
    expect(entries.current, isEmpty);

    final HtlcSwapEntry older = _buildEntry(id: 'older');
    await _writeEntries(dao, <HtlcSwapEntry>[older]);
    expect(await entries.moveNext(), isTrue);
    expect(entries.current, <HtlcSwapEntry>[older]);

    final HtlcSwapEntry newer = _buildEntry(
      id: 'newer',
      chainId: 2,
      startTime: 2,
    );
    await _writeEntries(dao, <HtlcSwapEntry>[newer]);
    expect(await entries.moveNext(), isTrue);
    expect(entries.current, <HtlcSwapEntry>[newer, older]);
  });

  test('stores checkpoints independently for each chain', () async {
    expect(await dao.readLastCheckedHtlcBlockHeight(1), 0);

    await dao.writeLastCheckedHtlcBlockHeight(1, 10);
    await dao.writeLastCheckedHtlcBlockHeight(2, 20);
    await dao.writeLastCheckedHtlcBlockHeight(1, 30);

    expect(await dao.readLastCheckedHtlcBlockHeight(1), 30);
    expect(await dao.readLastCheckedHtlcBlockHeight(2), 20);
  });

  test('deletes entries by id and chain-scoped state', () async {
    final HtlcSwapEntry active = _buildEntry(id: 'active');
    final HtlcSwapEntry completed = _buildEntry(
      id: 'completed',
      state: 'completed',
    );
    final HtlcSwapEntry otherChain = _buildEntry(
      id: 'other-chain',
      chainId: 2,
      state: 'completed',
    );
    await _writeEntries(dao, <HtlcSwapEntry>[active, completed, otherChain]);

    await dao.deleteSwapEntriesByState(1, <String>['completed']);
    expect(
      await dao.readAllSwapEntries(),
      unorderedEquals(<HtlcSwapEntry>[active, otherChain]),
    );

    await dao.deleteSwapEntry(active.id);
    expect(await dao.readAllSwapEntries(), <HtlcSwapEntry>[otherChain]);
  });

  test('prunes the oldest eligible entry when the limit is exceeded', () async {
    final HtlcSwapEntry oldest = _buildEntry(
      id: 'oldest',
      state: 'completed',
    );
    final HtlcSwapEntry active = _buildEntry(
      id: 'active',
      startTime: 2,
    );
    final HtlcSwapEntry newest = _buildEntry(
      id: 'newest',
      state: 'completed',
      startTime: 3,
    );

    await _writeEntries(
      dao,
      <HtlcSwapEntry>[oldest, active, newest],
      maximumStoredSwaps: 2,
    );

    expect(
      await dao.readAllSwapEntries(),
      unorderedEquals(<HtlcSwapEntry>[active, newest]),
    );
  });

  test('stores a processed block atomically', () async {
    final HtlcSwapEntry entry = _buildEntry(id: 'processed');

    await dao.writeProcessedHtlcBlock(
      chainId: 1,
      height: 10,
      updatedEntry: entry,
      maximumStoredSwaps: 100,
      prunableStates: const <String>['completed', 'unsuccessful'],
    );

    expect(await dao.readSwapEntryById(entry.id), entry);
    expect(await dao.readLastCheckedHtlcBlockHeight(1), 10);
  });

  test('rolls back a processed swap when its checkpoint fails', () async {
    await database.customStatement('''
      CREATE TRIGGER fail_htlc_checkpoint
      BEFORE INSERT ON htlc_scan_checkpoints
      BEGIN
        SELECT RAISE(FAIL, 'checkpoint failure');
      END;
    ''');

    await expectLater(
      dao.writeProcessedHtlcBlock(
        chainId: 1,
        height: 10,
        updatedEntry: _buildEntry(id: 'rolled-back'),
        maximumStoredSwaps: 100,
        prunableStates: const <String>['completed', 'unsuccessful'],
      ),
      throwsA(anything),
    );

    expect(await dao.readAllSwapEntries(), isEmpty);
    expect(await dao.readLastCheckedHtlcBlockHeight(1), 0);
  });

  test(
    'insertMissingSwapEntries inserts new entries without overwriting or '
    'pruning',
    () async {
      final HtlcSwapEntry existingCompleted = _buildEntry(
        id: 'existing',
        state: 'completed',
        startTime: 10,
      );
      await _writeEntries(dao, <HtlcSwapEntry>[existingCompleted]);

      final HtlcSwapEntry staleDuplicate = _buildEntry(id: 'existing');
      final HtlcSwapEntry migratedFirst = _buildEntry(
        id: 'migrated-1',
        startTime: 2,
      );
      final HtlcSwapEntry migratedSecond = _buildEntry(
        id: 'migrated-2',
        chainId: 2,
        startTime: 3,
      );

      await dao.insertMissingSwapEntries(<HtlcSwapEntry>[
        staleDuplicate,
        migratedFirst,
        migratedSecond,
      ]);

      expect(await dao.readSwapEntryById('existing'), existingCompleted);
      expect(
        await dao.readAllSwapEntries(),
        <HtlcSwapEntry>[existingCompleted, migratedSecond, migratedFirst],
      );
    },
  );
}

Future<void> _writeEntries(
  HtlcSwapsDao dao,
  List<HtlcSwapEntry> entries, {
  int maximumStoredSwaps = 100,
}) async {
  for (final HtlcSwapEntry entry in entries) {
    await dao.writeSwapEntry(
      entry,
      maximumStoredSwaps: maximumStoredSwaps,
      pruneChainId: entry.chainId,
      prunableStates: const <String>['completed', 'unsuccessful'],
    );
  }
}

HtlcSwapEntry _buildEntry({
  required String id,
  int chainId = 1,
  String state = 'active',
  int startTime = 1,
}) => HtlcSwapEntry(
  id: id,
  chainId: chainId,
  state: state,
  direction: 'incoming',
  hashLock: 'hash-lock-$id',
  initialHtlcId: 'initial-htlc-id-$id',
  counterHtlcId: 'counter-htlc-id-$id',
  startTime: startTime,
  payloadJson: '{"id":"$id"}',
);
