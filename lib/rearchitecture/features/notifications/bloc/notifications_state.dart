part of 'notifications_bloc.dart';

/// State representing the currently displayed wallet notification banner.
final class NotificationsState extends Equatable {
  /// Creates a [NotificationsState].
  const NotificationsState({
    this.activeNotification,
    this.revision = 0,
  });

  /// Notification currently shown in the wallet banner, or `null` when none is
  /// active or the latest notification was dismissed/cleared.
  final WalletNotification? activeNotification;

  /// Monotonically increasing counter incremented on each published
  /// notification so consecutive notifications with identical fields still
  /// trigger listeners.
  final int revision;

  /// Whether a notification banner is currently active and visible.
  bool get hasActiveNotification => activeNotification != null;

  @override
  List<Object?> get props => <Object?>[
    activeNotification?.id,
    activeNotification?.title,
    activeNotification?.details,
    activeNotification?.timestamp,
    activeNotification?.type,
    revision,
  ];
}
