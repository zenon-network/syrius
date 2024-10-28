import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/src/model/stats.dart';

class NotificationUtils {
  static Future<void> sendNotificationError(
    Object error,
    String title,
  ) async {
    Logger('NotificationUtils')
        .log(Level.WARNING, 'sendNotificationError', error);
    await sl.get<NotificationsBloc>().addErrorNotification(
          error,
          title,
        );
  }

  static bool shouldShowNotification() =>
      kLastNotification != null &&
      kLastNotification?.timestamp != kLastDismissedNotification?.timestamp;

  static Future<void> sendNodeSyncingNotification() async {
    final SyncInfo syncInfo = await zenon!.stats.syncInfo();
    if (syncInfo.targetHeight == 0 ||
        syncInfo.currentHeight == 0 ||
        (syncInfo.targetHeight - syncInfo.currentHeight) > 20) {
      await sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
              title:
                  'The node is still syncing with the network. Please wait until the loading circle turns green before sending any transactions',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details:
                  'The information displayed in the wallet does not reflect the most recent network state. Operations should not be performed, as they will likely become invalid by the time the node is fully synced',
              type: NotificationType.changedNode,
            ),
          );
    }
  }
}
