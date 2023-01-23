import 'dart:async';

import 'package:hive/hive.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class NotificationsBloc extends BaseBloc<WalletNotification?> {
  Future<void> addNotification(WalletNotification? notification) async {
    try {
      await Hive.openBox(kNotificationsBox);
      Box notificationsBox = Hive.box(kNotificationsBox);
      if (notificationsBox.length >= kNotificationsEntriesLimit) {
        while (notificationsBox.length >= kNotificationsEntriesLimit) {
          await notificationsBox.delete(notificationsBox.keys.first);
        }
      }
      await notificationsBox.add(notification);
      if (notification != null && _areDesktopNotificationsEnabled()) {
        LocalNotification localNotification = LocalNotification(
          title: notification.title ?? 'Empty title',
          body: notification.details ?? 'No details available',
        );
        localNotification.show();
      }
      addEvent(notification);
    } catch (e) {
      addError(e);
    }
  }

  sendPlasmaNotification(String purposeOfGeneratingPlasma) {
    addNotification(
      WalletNotification(
        title: 'Plasma will be generated in order to '
            '$purposeOfGeneratingPlasma',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Plasma will be generated for this account-block',
        type: NotificationType.generatingPlasma,
      ),
    );
  }

  addErrorNotification(Object error, String title) {
    addNotification(
      WalletNotification(
        title: title,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: '$title: ${error.toString()}',
        type: NotificationType.error,
      ),
    );
  }

  bool _areDesktopNotificationsEnabled() => sharedPrefsService!.get(
        kEnableDesktopNotificationsKey,
        defaultValue: kEnableDesktopNotificationsDefaultValue,
      );
}
