import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/data/notifications_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Callback that displays a system desktop notification.
typedef DesktopNotificationPresenter =
    Future<void> Function(WalletNotification notification);

/// Manages storing wallet notifications, surfacing desktop alerts, and tracking
/// the currently active in-app notification banner.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  /// Creates a [NotificationsBloc].
  NotificationsBloc({
    NotificationsRepository? repository,
    bool Function()? isDesktopPlatformCheck,
    bool Function()? isDesktopNotificationsEnabled,
    DesktopNotificationPresenter? showDesktopNotification,
    DateTime Function()? now,
  }) : _repository = repository ?? const HiveNotificationsRepository(),
       _isDesktopPlatformCheck = isDesktopPlatformCheck ?? isDesktopPlatform,
       _isDesktopNotificationsEnabled =
           isDesktopNotificationsEnabled ??
           _defaultIsDesktopNotificationsEnabled,
       _showDesktopNotification =
           showDesktopNotification ?? _defaultShowDesktopNotification,
       _now = now ?? DateTime.now,
       super(const NotificationsState()) {
    on<NotificationsEvent>(_onEvent, transformer: sequential());
  }

  final NotificationsRepository _repository;
  final bool Function() _isDesktopPlatformCheck;
  final bool Function() _isDesktopNotificationsEnabled;
  final DesktopNotificationPresenter _showDesktopNotification;
  final DateTime Function() _now;
  final Set<Completer<void>> _pendingCompleters = <Completer<void>>{};

  /// Stores [notification] in history without showing it to the user.
  Future<void> recordNotification(WalletNotification notification) => _dispatch(
    (Completer<void> completer) =>
        NotificationRecorded(notification, completer: completer),
  );

  /// Stores and publishes [notification] to wallet and desktop surfaces.
  ///
  /// Passing `null` clears the active notification banner without writing an
  /// entry to history.
  Future<void> addNotification(WalletNotification? notification) {
    if (notification == null) {
      return clearNotification();
    }
    return _dispatch(
      (Completer<void> completer) =>
          NotificationAdded(notification, completer: completer),
    );
  }

  /// Dismisses the currently visible notification banner.
  Future<void> dismissNotification() => _dispatch(
    (Completer<void> completer) => NotificationDismissed(completer: completer),
  );

  /// Clears the currently visible notification banner without writing to
  /// history.
  Future<void> clearNotification() => _dispatch(
    (Completer<void> completer) =>
        NotificationBannerCleared(completer: completer),
  );

  /// Publishes a plasma generation notification for
  /// [purposeOfGeneratingPlasma].
  Future<void> sendPlasmaNotification(String purposeOfGeneratingPlasma) {
    return addNotification(
      WalletNotification(
        title:
            'Plasma will be generated in order to '
            '$purposeOfGeneratingPlasma',
        timestamp: _now().millisecondsSinceEpoch,
        details: 'Plasma will be generated for this account-block',
        type: NotificationType.generatingPlasma,
      ),
    );
  }

  /// Stores and publishes an error notification with [title] and [error].
  Future<void> addErrorNotification(Object error, String title) {
    return addNotification(
      WalletNotification(
        title: title,
        timestamp: _now().millisecondsSinceEpoch,
        details: '$title: $error',
        type: NotificationType.error,
      ),
    );
  }

  /// Stores an error in history without showing it to the user.
  Future<void> recordErrorNotification(Object error, String title) {
    return recordNotification(
      WalletNotification(
        title: title,
        timestamp: _now().millisecondsSinceEpoch,
        details: '$title: $error',
        type: NotificationType.error,
      ),
    );
  }

  Future<void> _dispatch(
    NotificationsEvent Function(Completer<void> completer) buildEvent,
  ) {
    if (isClosed) {
      return Future<void>.value();
    }
    final Completer<void> completer = Completer<void>();
    _pendingCompleters.add(completer);
    try {
      add(buildEvent(completer));
    } on Object {
      _pendingCompleters.remove(completer);
      if (!completer.isCompleted) {
        completer.complete();
      }
      rethrow;
    }
    return completer.future;
  }

  Future<void> _onEvent(
    NotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      switch (event) {
        case NotificationAdded():
          await _onAdded(event, emit);
        case NotificationRecorded():
          await _onRecorded(event);
        case NotificationDismissed():
          emit(NotificationsState(revision: state.revision));
        case NotificationBannerCleared():
          emit(NotificationsState(revision: state.revision));
      }
    } finally {
      final Completer<void>? completer = event._completer;
      if (completer != null) {
        _pendingCompleters.remove(completer);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
  }

  Future<void> _onAdded(
    NotificationAdded event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await _repository.addNotification(event.notification);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      return;
    }

    if (_isDesktopPlatformCheck() && _isDesktopNotificationsEnabled()) {
      try {
        await _showDesktopNotification(event.notification);
      } on Object catch (error, stackTrace) {
        addError(error, stackTrace);
      }
    }

    emit(
      NotificationsState(
        activeNotification: event.notification,
        revision: state.revision + 1,
      ),
    );
  }

  Future<void> _onRecorded(NotificationRecorded event) async {
    try {
      await _repository.addNotification(event.notification);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  static bool _defaultIsDesktopNotificationsEnabled() {
    final SharedPrefsService? prefs = sharedPrefsService;
    if (prefs == null) {
      return false;
    }
    final dynamic stored = prefs.get(
      kEnableDesktopNotificationsKey,
      defaultValue: kEnableDesktopNotificationsDefaultValue,
    );
    return stored is bool ? stored : kEnableDesktopNotificationsDefaultValue;
  }

  static Future<void> _defaultShowDesktopNotification(
    WalletNotification notification,
  ) async {
    await desktopNotificationsPlugin.show(
      id: (notification.timestamp ?? DateTime.now().millisecondsSinceEpoch)
          .hashCode,
      title: notification.title ?? 'Empty title',
      body: notification.details ?? 'No details available',
    );
  }

  @override
  Future<void> close() async {
    try {
      await super.close();
    } finally {
      for (final Completer<void> completer in List<Completer<void>>.of(
        _pendingCompleters,
      )) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
      _pendingCompleters.clear();
    }
  }
}
