import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/syrius_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/l10n/app_localizations_resolver.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Utilities for displaying foreground toasts and recording wallet
/// notifications.
class NotificationUtils {
  /// Shows a foreground toast for [notification] and persists it in
  /// [NotificationsBloc].
  static Future<void> showForegroundNotification(
    BuildContext context,
    WalletNotification notification, {
    String? toastMessage,
  }) async {
    ToastUtils.showToast(context, toastMessage ?? notification.title ?? '');
    await sl.get<NotificationsBloc>().recordNotification(notification);
  }

  /// Logs [error], shows a localized foreground error toast, and records an
  /// error notification with [title].
  static Future<void> showForegroundError(
    BuildContext context,
    Object error,
    String title,
  ) async {
    final String errorMessage = _resolveErrorMessage(
      error,
      AppLocalizations.of(context) ?? resolveAppLocalizations(),
    );
    Logger(
      'NotificationUtils',
    ).log(Level.WARNING, 'showForegroundError', error);
    ToastUtils.showToast(context, errorMessage, color: AppColors.errorColor);
    await sl.get<NotificationsBloc>().recordErrorNotification(
      errorMessage,
      title,
    );
  }

  /// Logs [error] and dispatches a localized error notification with [title].
  static Future<void> sendNotificationError(Object error, String title) async {
    final String errorMessage = _resolveErrorMessage(
      error,
      resolveAppLocalizations(),
    );
    Logger(
      'NotificationUtils',
    ).log(Level.WARNING, 'sendNotificationError', error);
    await sl.get<NotificationsBloc>().addErrorNotification(errorMessage, title);
  }

  static String _resolveErrorMessage(Object error, AppLocalizations l10n) =>
      error is SyriusException
      ? error.localizedMessage(l10n)
      : error.toString();

  /// Returns the currently active notification banner, if any.
  static WalletNotification? activeNotification() =>
      sl.isRegistered<NotificationsBloc>()
      ? sl<NotificationsBloc>().state.activeNotification
      : null;

  /// Returns `true` when there is an active notification banner to display.
  static bool shouldShowNotification() => activeNotification() != null;

  /// Sends a warning notification if the connected node is still syncing.
  static Future<void> sendNodeSyncingNotification() async {
    final SyncInfo syncInfo = await zenon!.stats.syncInfo();
    if (syncInfo.targetHeight == 0 ||
        syncInfo.currentHeight == 0 ||
        (syncInfo.targetHeight - syncInfo.currentHeight) > 20) {
      await sl.get<NotificationsBloc>().addNotification(
        WalletNotification(
          title:
              'The node is still syncing with the network. Please wait until '
              'the loading circle turns green before sending any transactions',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details:
              'The information displayed in the wallet does not reflect the '
              'most recent network state. Operations should not be performed, '
              'as they will likely become invalid by the time the node is '
              'fully synced',
          type: NotificationType.changedNode,
        ),
      );
    }
  }
}
