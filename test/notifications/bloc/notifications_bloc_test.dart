import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_registrar.g.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = Directory.systemTemp.createTempSync(
      'syrius_notifications_bloc_test_',
    );
    Hive.init(hiveDirectory.path);
    Hive.registerAdapters();
  });

  tearDown(() async {
    if (Hive.isBoxOpen(kNotificationsBox)) {
      await Hive.box(kNotificationsBox).clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'recordNotification stores history without publishing an event',
    () async {
      final NotificationsBloc bloc = NotificationsBloc();
      final List<WalletNotification?> events = <WalletNotification?>[];
      final StreamSubscription<WalletNotification?> subscription = bloc.stream
          .listen(events.add);
      final WalletNotification notification = WalletNotification(
        title: 'Swap started',
        timestamp: 1000,
        details: 'Hash: 123',
        type: NotificationType.paymentSent,
      );

      await bloc.recordNotification(notification);
      await Future<void>.delayed(Duration.zero);

      final Box box = Hive.box(kNotificationsBox);
      final WalletNotification stored = box.values.single as WalletNotification;
      expect(stored.title, notification.title);
      expect(stored.timestamp, notification.timestamp);
      expect(stored.details, notification.details);
      expect(stored.type, notification.type);
      expect(events, isEmpty);

      await subscription.cancel();
      bloc.dispose();
    },
  );
}
