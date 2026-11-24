import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/sync_info_extension.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  group('SyncInfoExtension', () {
    test('trusts the explicit sync done state', () {
      final SyncInfo syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncDone.index,
        'currentHeight': 0,
        'targetHeight': 0,
      });

      expect(syncInfo.isSynced, isTrue);
      expect(syncInfo.isClearlyBehind, isFalse);
    });

    test('considers a node within the tolerance synced', () {
      final SyncInfo syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncing.index,
        'currentHeight': 98,
        'targetHeight': 100,
      });

      expect(syncInfo.isSynced, isTrue);
      expect(syncInfo.isClearlyBehind, isFalse);
    });

    test('considers a node at the tolerance boundary behind', () {
      final SyncInfo syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncing.index,
        'currentHeight': 97,
        'targetHeight': 100,
      });

      expect(syncInfo.isSynced, isFalse);
      expect(syncInfo.isClearlyBehind, isTrue);
    });

    test('rejects uninitialized heights', () {
      final SyncInfo syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': SyncState.syncing.index,
        'currentHeight': 0,
        'targetHeight': 0,
      });

      expect(syncInfo.isSynced, isFalse);
      expect(syncInfo.isClearlyBehind, isFalse);
    });
  });
}
