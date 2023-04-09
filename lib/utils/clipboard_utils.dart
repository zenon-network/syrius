import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

class ClipboardUtils {

  static void toggleClipboardWatcherStatus() {
    final enableClipboardWatcher = sharedPrefsService!.get(
      kEnableClipboardWatcherKey,
      defaultValue: kEnableClipboardWatcherDefaultValue,
    );
    if (enableClipboardWatcher) {
      clipboardWatcher.start();
    } else {
      kLastWalletConnectUri = null;
      clipboardWatcher.stop();
    }
  }

  static void copyToClipboard(String stringValue, BuildContext context) {
    Clipboard.setData(
      ClipboardData(
        text: stringValue,
      ),
    ).then((value) =>
        sl.get<NotificationsBloc>().addNotification(WalletNotification(
              timestamp: DateTime.now().millisecondsSinceEpoch,
              title: 'Successfully copied to clipboard',
              details: 'Successfully copied $stringValue to clipboard',
              type: NotificationType.copiedToClipboard,
              id: null,
            )));
  }

  static void pasteToClipboard(
      BuildContext context, Function(String) callback) {
    Clipboard.getData('text/plain').then((value) {
      if (value != null) {
        callback(value.text!);
      } else {
        NotificationUtils.sendNotificationError(
          Exception('The clipboard data could not be obtained'),
          'Something went wrong while getting the clipboard data',
        );
      }
    });
  }
}
