import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_registrar.g.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';

void main() {
  group('HiveNotificationsRepository', () {
    late Directory hiveDirectory;
    late String boxName;
    late HiveNotificationsRepository repository;
    int boxCounter = 0;

    setUpAll(() {
      hiveDirectory = Directory.systemTemp.createTempSync(
        'syrius_notifications_repo_test_',
      );
      Hive
        ..init(hiveDirectory.path)
        ..registerAdapters();
    });

    tearDownAll(() async {
      await Hive.close();
      if (hiveDirectory.existsSync()) {
        hiveDirectory.deleteSync(recursive: true);
      }
    });

    setUp(() {
      boxName = 'notifications_test_${boxCounter++}';
      repository = HiveNotificationsRepository(boxName: boxName);
    });

    tearDown(() async {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<dynamic>(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
    });

    WalletNotification makeNotification({
      required String title,
      required int? timestamp,
      String details = 'Details',
    }) {
      return WalletNotification(
        title: title,
        timestamp: timestamp,
        details: details,
        type: NotificationType.paymentReceived,
      );
    }

    test(
      'filters null sentinel entries, sorts newest-first, and respects limit',
      () async {
        final Box<dynamic> box = await Hive.openBox<dynamic>(boxName);
        await box.add(null);
        await box.add(makeNotification(title: 'Older', timestamp: 1000));
        await box.add(makeNotification(title: 'Tie A', timestamp: 2000));
        await box.add(makeNotification(title: 'Tie B', timestamp: 2000));
        await box.add(null);
        await box.add(makeNotification(title: 'Newest', timestamp: 3000));

        final List<StoredWalletNotification> all = await repository
            .loadNotifications();
        expect(
          all.map((StoredWalletNotification e) => e.notification.title),
          equals(<String?>['Newest', 'Tie B', 'Tie A', 'Older']),
        );

        final List<StoredWalletNotification> limited = await repository
            .loadNotifications(limit: 2);
        expect(
          limited.map((StoredWalletNotification e) => e.notification.title),
          equals(<String?>['Newest', 'Tie B']),
        );

        final List<StoredWalletNotification> zeroLimit = await repository
            .loadNotifications(limit: 0);
        expect(zeroLimit, isEmpty);
      },
    );

    test(
      'deletes exact record by Hive key even with identical timestamps',
      () async {
        final Box<dynamic> box = await Hive.openBox<dynamic>(boxName);
        await box.add(makeNotification(title: 'First', timestamp: 5000));
        await box.add(makeNotification(title: 'Second', timestamp: 5000));

        final List<StoredWalletNotification> loaded = await repository
            .loadNotifications();
        expect(loaded.length, 2);

        final StoredWalletNotification firstRecord = loaded.firstWhere(
          (StoredWalletNotification e) => e.notification.title == 'First',
        );
        await repository.deleteNotification(firstRecord.key);

        final List<StoredWalletNotification> remaining = await repository
            .loadNotifications();
        expect(remaining.length, 1);
        expect(remaining.single.notification.title, equals('Second'));
      },
    );

    test('clearAllNotifications empties the box', () async {
      final Box<dynamic> box = await Hive.openBox<dynamic>(boxName);
      await box.add(makeNotification(title: 'One', timestamp: 1000));
      await box.add(makeNotification(title: 'Two', timestamp: 2000));

      await repository.clearAllNotifications();

      expect(await repository.loadNotifications(), isEmpty);
      expect(box.isEmpty, isTrue);
    });

    test('watchChanges emits on add, delete, and clear', () async {
      final Box<dynamic> box = await Hive.openBox<dynamic>(boxName);
      int eventCount = 0;
      final Completer<void> firstEvent = Completer<void>();

      final StreamSubscription<void> sub = repository.watchChanges().listen((
        _,
      ) {
        eventCount++;
        if (!firstEvent.isCompleted) {
          firstEvent.complete();
        }
      });
      addTearDown(sub.cancel);

      await Future<void>.delayed(Duration.zero);
      final int key = await box.add(
        makeNotification(title: 'Watched', timestamp: 4000),
      );
      await firstEvent.future.timeout(const Duration(seconds: 2));
      await repository.deleteNotification(key);
      await box.add(makeNotification(title: 'Watched 2', timestamp: 5000));
      await repository.clearAllNotifications();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(eventCount, greaterThanOrEqualTo(3));
    });
  });
}
