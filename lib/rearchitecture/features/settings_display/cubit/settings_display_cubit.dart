import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_display/model/display_settings_enums.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

part 'settings_display_state.dart';

/// Manages persisting display preferences (theme mode, text scaling, locale).
class SettingsDisplayCubit extends Cubit<SettingsDisplayState> {
  /// Creates a [SettingsDisplayCubit].
  SettingsDisplayCubit({
    this._prefsService,
    this._addNotification,
    this._reportError,
  }) : super(const SettingsDisplayState());

  final SharedPrefsService? _prefsService;
  final Future<void> Function(WalletNotification notification)?
  _addNotification;
  final Future<void> Function(Object error, String title)? _reportError;

  SharedPrefsService get _prefs => _prefsService ?? sharedPrefsService!;

  /// Updates the selected [locale] in state.
  void selectLocale(LocaleType locale) {
    emit(state.copyWith(selectedLocale: locale));
  }

  /// Persists [themeMode] and records a confirmation notification.
  Future<void> confirmThemeMode({
    required ThemeMode? themeMode,
    required String notificationTitle,
    required String notificationDetails,
    required String errorTitle,
  }) async {
    emit(state.copyWith(isSavingTheme: true));
    try {
      await _prefs.put(kThemeModeKey, themeMode.toString());
      await _sendNotification(
        WalletNotification(
          title: notificationTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: notificationDetails,
          type: NotificationType.paymentSent,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (isClosed) {
        return;
      }
      addError(error, stackTrace);
      await _sendError(error, errorTitle);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isSavingTheme: false));
      }
    }
  }

  /// Persists [textScaling] and records a confirmation notification.
  Future<void> confirmTextScaling({
    required TextScaling? textScaling,
    required String notificationTitle,
    required String notificationDetails,
    required String errorTitle,
  }) async {
    emit(state.copyWith(isSavingTextScaling: true));
    try {
      await _prefs.put(kTextScalingKey, textScaling.toString());
      await _sendNotification(
        WalletNotification(
          title: notificationTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: notificationDetails,
          type: NotificationType.paymentSent,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (isClosed) {
        return;
      }
      addError(error, stackTrace);
      await _sendError(error, errorTitle);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isSavingTextScaling: false));
      }
    }
  }

  Future<void> _sendNotification(WalletNotification notification) async {
    if (_addNotification != null) {
      await _addNotification(notification);
      return;
    }
    await sl.get<NotificationsBloc>().addNotification(notification);
  }

  Future<void> _sendError(Object error, String title) async {
    if (_reportError != null) {
      await _reportError(error, title);
      return;
    }
    await NotificationUtils.sendNotificationError(error, title);
  }
}
