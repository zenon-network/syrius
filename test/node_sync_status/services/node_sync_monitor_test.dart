import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockStatsApi extends Mock implements StatsApi {}

class MockZenon extends Mock implements Zenon {}

void main() {
  group('NodeSyncMonitor', () {
    late MockStatsApi statsApi;
    late MockZenon zenon;
    late NodeSyncMonitor monitor;
    late SyncInfo syncInfo;

    setUp(() {
      statsApi = MockStatsApi();
      zenon = MockZenon();
      syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncing.index,
        'currentHeight': 98,
        'targetHeight': 100,
      });

      when(() => zenon.stats).thenReturn(statsApi);
      monitor = NodeSyncMonitor(zenon: zenon);
    });

    test('fetches the current sync info', () async {
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);

      expect(await monitor.fetch(), same(syncInfo));
      verify(() => statsApi.syncInfo()).called(1);
    });

    test('shares an in-flight request', () async {
      final Completer<SyncInfo> completer = Completer<SyncInfo>();
      when(() => statsApi.syncInfo()).thenAnswer((_) => completer.future);

      final Future<SyncInfo> first = monitor.fetch();
      final Future<SyncInfo> second = monitor.fetch();
      completer.complete(syncInfo);

      expect(await first, same(syncInfo));
      expect(await second, same(syncInfo));
      verify(() => statsApi.syncInfo()).called(1);
    });

    test('fetches fresh sync info after a request completes', () async {
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);

      await monitor.fetch();
      await monitor.fetch();

      verify(() => statsApi.syncInfo()).called(2);
    });

    test('can retry after a request fails', () async {
      int attempts = 0;
      when(() => statsApi.syncInfo()).thenAnswer((_) async {
        attempts += 1;
        if (attempts == 1) {
          throw Exception('sync info unavailable');
        }
        return syncInfo;
      });

      await expectLater(monitor.fetch(), throwsException);
      expect(await monitor.fetch(), same(syncInfo));
      verify(() => statsApi.syncInfo()).called(2);
    });

    test('can retry after a synchronous failure', () async {
      int attempts = 0;
      when(() => statsApi.syncInfo()).thenAnswer((_) {
        attempts += 1;
        if (attempts == 1) {
          throw StateError('sync info unavailable synchronously');
        }
        return Future<SyncInfo>.value(syncInfo);
      });

      await expectLater(monitor.fetch(), throwsStateError);
      expect(await monitor.fetch(), same(syncInfo));
      verify(() => statsApi.syncInfo()).called(2);
    });

    test('considers a node near the target height synced', () async {
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);

      expect(await monitor.isNodeSynced(), isTrue);
    });

    test('does not consider a node three momentums behind synced', () async {
      syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncing.index,
        'currentHeight': 97,
        'targetHeight': 100,
      });
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);

      expect(await monitor.isNodeSynced(), isFalse);
    });

    test('trusts the explicit sync done state', () async {
      syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncDone.index,
        'currentHeight': 0,
        'targetHeight': 0,
      });
      when(() => statsApi.syncInfo()).thenAnswer((_) async => syncInfo);

      expect(await monitor.isNodeSynced(), isTrue);
    });

    test('returns false when sync information cannot be fetched', () async {
      when(
        () => statsApi.syncInfo(),
      ).thenThrow(Exception('sync info unavailable'));

      expect(await monitor.isNodeSynced(), isFalse);
    });
  });
}
