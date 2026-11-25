part of 'notifications_bloc.dart';

/// Base event for [NotificationsBloc].
sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent({this._completer});

  final Completer<void>? _completer;

  @override
  List<Object?> get props => const <Object?>[];
}

/// Persists [notification] in history, optionally shows a desktop notification,
/// and publishes it to the active in-app banner.
final class NotificationAdded extends NotificationsEvent {
  /// Creates a [NotificationAdded] event.
  const NotificationAdded(this.notification, {super.completer});

  /// Notification to persist and publish.
  final WalletNotification notification;

  @override
  List<Object?> get props => <Object?>[
    notification.id,
    notification.title,
    notification.details,
    notification.timestamp,
    notification.type,
  ];
}

/// Persists [notification] in history without publishing it to the banner or
/// desktop notification surfaces.
final class NotificationRecorded extends NotificationsEvent {
  /// Creates a [NotificationRecorded] event.
  const NotificationRecorded(this.notification, {super.completer});

  /// Notification to persist silently in history.
  final WalletNotification notification;

  @override
  List<Object?> get props => <Object?>[
    notification.id,
    notification.title,
    notification.details,
    notification.timestamp,
    notification.type,
  ];
}

/// Dismisses the currently visible notification banner.
final class NotificationDismissed extends NotificationsEvent {
  /// Creates a [NotificationDismissed] event.
  const NotificationDismissed({super.completer});
}

/// Clears the currently visible notification banner without writing to history.
final class NotificationBannerCleared extends NotificationsEvent {
  /// Creates a [NotificationBannerCleared] event.
  const NotificationBannerCleared({super.completer});
}
