import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

part 'settings_wallet_options_event.dart';
part 'settings_wallet_options_state.dart';

/// Manages wallet preferences in the Settings Wallet Options card.
class SettingsWalletOptionsBloc
    extends Bloc<SettingsWalletOptionsEvent, SettingsWalletOptionsState> {
  /// Creates a [SettingsWalletOptionsBloc].
  factory SettingsWalletOptionsBloc({
    SharedPrefsService? prefsService,
    Future<void> Function({required bool enabled})? configureLaunchAtStartup,
    Future<bool> Function()? requestMacOsNotificationPermissions,
    bool? isMacOs,
    void Function()? toggleClipboardWatcher,
    Future<void> Function()? triggerAutoReceive,
    void Function()? clearAutoReceivePool,
    Future<void> Function(WalletNotification notification)? addNotification,
    Future<void> Function(Object error, String title)? reportError,
  }) {
    final SharedPrefsService prefs = prefsService ?? sharedPrefsService!;
    return SettingsWalletOptionsBloc._(
      prefs: prefs,
      configureLaunchAtStartup: configureLaunchAtStartup,
      requestMacOsNotificationPermissions: requestMacOsNotificationPermissions,
      isMacOs: isMacOs ?? Platform.isMacOS,
      toggleClipboardWatcher: toggleClipboardWatcher,
      triggerAutoReceive: triggerAutoReceive,
      clearAutoReceivePool: clearAutoReceivePool,
      addNotification: addNotification,
      reportError: reportError,
      initialState: SettingsWalletOptionsState(
        launchAtStartup:
            prefs.get(
                  kLaunchAtStartupKey,
                  defaultValue: kLaunchAtStartupDefaultValue,
                )
                as bool,
        enableDesktopNotifications:
            prefs.get(
                  kEnableDesktopNotificationsKey,
                  defaultValue: kEnableDesktopNotificationsDefaultValue,
                )
                as bool,
        enableClipboardWatcher:
            prefs.get(
                  kEnableClipboardWatcherKey,
                  defaultValue: kEnableClipboardWatcherDefaultValue,
                )
                as bool,
        autoReceive:
            prefs.get(kAutoReceiveKey, defaultValue: kAutoReceiveDefaultValue)
                as bool,
      ),
    );
  }

  SettingsWalletOptionsBloc._({
    required this._prefs,
    required this._isMacOs,
    required SettingsWalletOptionsState initialState,
    this._configureLaunchAtStartup,
    this._requestMacOsNotificationPermissions,
    this._toggleClipboardWatcher,
    this._triggerAutoReceive,
    this._clearAutoReceivePool,
    this._addNotification,
    this._reportError,
  }) : super(initialState) {
    on<SettingsWalletOptionsLaunchAtStartupToggled>(_onLaunchAtStartupToggled);
    on<SettingsWalletOptionsDesktopNotificationsToggled>(
      _onDesktopNotificationsToggled,
    );
    on<SettingsWalletOptionsClipboardWatcherToggled>(
      _onClipboardWatcherToggled,
    );
    on<SettingsWalletOptionsAutoReceiveToggled>(_onAutoReceiveToggled);
  }

  final SharedPrefsService _prefs;
  final bool _isMacOs;
  final Future<void> Function({required bool enabled})?
  _configureLaunchAtStartup;
  final Future<bool> Function()? _requestMacOsNotificationPermissions;
  final void Function()? _toggleClipboardWatcher;
  final Future<void> Function()? _triggerAutoReceive;
  final void Function()? _clearAutoReceivePool;
  final Future<void> Function(WalletNotification notification)?
  _addNotification;
  final Future<void> Function(Object error, String title)? _reportError;

  FutureOr<void> _onLaunchAtStartupToggled(
    SettingsWalletOptionsLaunchAtStartupToggled event,
    Emitter<SettingsWalletOptionsState> emit,
  ) async {
    final bool previous = state.launchAtStartup;
    emit(state.copyWith(launchAtStartup: event.enabled));
    try {
      await _applyLaunchAtStartup(event.enabled);
      await _prefs.put(kLaunchAtStartupKey, event.enabled);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(launchAtStartup: previous));
      await _sendError(error, event.errorTitle);
      return;
    }
    await _trySendNotification(
      WalletNotification(
        title: event.notificationTitle,
        details: event.notificationDetails,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: NotificationType.paymentSent,
      ),
      errorTitle: event.errorTitle,
    );
  }

  FutureOr<void> _onDesktopNotificationsToggled(
    SettingsWalletOptionsDesktopNotificationsToggled event,
    Emitter<SettingsWalletOptionsState> emit,
  ) async {
    if (event.enabled && _isMacOs) {
      final bool permissionGranted = await _requestMacOsPermissions();
      if (!permissionGranted) {
        return;
      }
    }

    final bool previous = state.enableDesktopNotifications;
    emit(state.copyWith(enableDesktopNotifications: event.enabled));
    try {
      await _prefs.put(kEnableDesktopNotificationsKey, event.enabled);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(enableDesktopNotifications: previous));
      await _sendError(error, event.errorTitle);
      return;
    }
    await _trySendNotification(
      WalletNotification(
        title: event.notificationTitle,
        details: event.notificationDetails,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: NotificationType.paymentSent,
      ),
      errorTitle: event.errorTitle,
    );
  }

  FutureOr<void> _onClipboardWatcherToggled(
    SettingsWalletOptionsClipboardWatcherToggled event,
    Emitter<SettingsWalletOptionsState> emit,
  ) async {
    final bool previous = state.enableClipboardWatcher;
    emit(state.copyWith(enableClipboardWatcher: event.enabled));
    try {
      await _prefs.put(kEnableClipboardWatcherKey, event.enabled);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(enableClipboardWatcher: previous));
      await _sendError(error, event.errorTitle);
      return;
    }
    try {
      (_toggleClipboardWatcher ?? ClipboardUtils.toggleClipboardWatcherStatus)
          .call();
      await _sendNotification(
        WalletNotification(
          title: event.notificationTitle,
          details: event.notificationDetails,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: NotificationType.paymentSent,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _sendError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onAutoReceiveToggled(
    SettingsWalletOptionsAutoReceiveToggled event,
    Emitter<SettingsWalletOptionsState> emit,
  ) async {
    final bool previous = state.autoReceive;
    emit(state.copyWith(autoReceive: event.enabled));
    try {
      await _prefs.put(kAutoReceiveKey, event.enabled);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(autoReceive: previous));
      await _sendError(error, event.errorTitle);
      return;
    }
    try {
      if (event.enabled) {
        unawaited(_runAutoReceive());
      } else {
        _clearPool();
      }
      await _sendNotification(
        WalletNotification(
          title: event.notificationTitle,
          details: event.notificationDetails,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: NotificationType.paymentSent,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _sendError(error, event.errorTitle);
    }
  }

  Future<void> _trySendNotification(
    WalletNotification notification, {
    required String errorTitle,
  }) async {
    try {
      await _sendNotification(notification);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _sendError(error, errorTitle);
    }
  }

  Future<void> _applyLaunchAtStartup(bool enabled) async {
    if (_configureLaunchAtStartup != null) {
      await _configureLaunchAtStartup(enabled: enabled);
      return;
    }
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }

  Future<bool> _requestMacOsPermissions() async {
    if (_requestMacOsNotificationPermissions != null) {
      return await _requestMacOsNotificationPermissions();
    }
    final MacOSFlutterLocalNotificationsPlugin? plugin =
        desktopNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
    return await plugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<void> _runAutoReceive() async {
    try {
      if (_triggerAutoReceive != null) {
        await _triggerAutoReceive();
        return;
      }
      await NodeUtils.getUnreceivedTransactions();
      await sl<AutoReceiveTxWorker>().autoReceive();
    } on Object catch (error, stackTrace) {
      Logger(
        'SettingsWalletOptionsBloc',
      ).log(Level.WARNING, '_runAutoReceive', error, stackTrace);
    }
  }

  void _clearPool() {
    if (_clearAutoReceivePool != null) {
      _clearAutoReceivePool();
      return;
    }
    if (sl<AutoReceiveTxWorker>().pool.isNotEmpty) {
      sl<AutoReceiveTxWorker>().pool.clear();
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
