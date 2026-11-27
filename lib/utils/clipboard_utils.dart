import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Utilities for clipboard read/write actions and clipboard watcher control.
class ClipboardUtils {
  /// Starts or stops the system clipboard watcher according to user settings.
  static void toggleClipboardWatcherStatus() {
    final bool enableClipboardWatcher = sharedPrefsService!.get(
      kEnableClipboardWatcherKey,
      defaultValue: kEnableClipboardWatcherDefaultValue,
    );
    if (enableClipboardWatcher) {
      unawaited(clipboardWatcher.start());
    } else {
      kLastWalletConnectUriNotifier.value = null;
      unawaited(clipboardWatcher.stop());
    }
  }

  /// Copies [stringValue] to the clipboard and shows a confirmation toast.
  static void copyToClipboard(String stringValue, BuildContext context) {
    unawaited(
      Clipboard.setData(ClipboardData(text: stringValue)).then((_) {
        if (context.mounted) {
          ToastUtils.showToast(context, 'Copied', color: AppColors.znnColor);
        }
      }),
    );
  }

  /// Reads plain text from the clipboard and passes non-empty text to
  /// [callback], or emits an error notification if unavailable.
  static void pasteToClipboard({required Function(String) callback}) {
    unawaited(
      Clipboard.getData('text/plain').then((ClipboardData? value) async {
        final String? text = value?.text;
        if (text != null && text.isNotEmpty) {
          callback(text);
        } else {
          await NotificationUtils.sendNotificationError(
            Exception('The clipboard data could not be obtained'),
            'Something went wrong while getting the clipboard data',
          );
        }
      }),
    );
  }
}
