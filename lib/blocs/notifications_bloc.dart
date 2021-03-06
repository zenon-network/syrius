import 'dart:async';

import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
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
}
