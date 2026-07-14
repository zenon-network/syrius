import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_adapters.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_registrar.g.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() {
    hiveDirectory = Directory.systemTemp.createTempSync('syrius_hive_test_');
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

  test('keeps legacy type ids', () {
    expect(WalletNotificationAdapter().typeId, 100);
    expect(NotificationTypeAdapter().typeId, 101);
  });

  test('round trips wallet notifications and null entries', () async {
    final Box<WalletNotification?> notificationsBox =
        await Hive.openBox<WalletNotification?>('notifications');
    final WalletNotification notification = WalletNotification(
      title: 'Test notification',
      timestamp: 123456789,
      details: 'Test details',
      type: NotificationType.paymentReceived,
      id: 7,
    );

    await notificationsBox.add(notification);
    await notificationsBox.add(null);
    await notificationsBox.close();

    final Box<WalletNotification?> reopenedBox =
        await Hive.openBox<WalletNotification?>('notifications');
    final WalletNotification? storedNotification = reopenedBox.getAt(0);

    expect(storedNotification?.title, notification.title);
    expect(storedNotification?.timestamp, notification.timestamp);
    expect(storedNotification?.details, notification.details);
    expect(storedNotification?.type, notification.type);
    expect(storedNotification?.id, notification.id);
    expect(reopenedBox.getAt(1), isNull);
  });
}
