part of 'notifications_list_bloc.dart';

/// Base event for [NotificationsListBloc].
sealed class NotificationsListEvent extends Equatable {
  const NotificationsListEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Initializes watching and loads the stored notifications list.
final class NotificationsListStarted extends NotificationsListEvent {
  /// Creates a [NotificationsListStarted] event.
  const NotificationsListStarted();
}

/// Manually reloads stored notifications from the repository.
final class NotificationsListRefreshRequested extends NotificationsListEvent {
  /// Creates a [NotificationsListRefreshRequested] event.
  const NotificationsListRefreshRequested();
}

/// Deletes a single stored notification identified by [key].
final class NotificationDeleteRequested extends NotificationsListEvent {
  /// Creates a [NotificationDeleteRequested] event.
  const NotificationDeleteRequested({required this.key});

  /// Hive storage key of the notification to delete.
  final dynamic key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// Deletes every stored notification in history.
final class NotificationsClearAllRequested extends NotificationsListEvent {
  /// Creates a [NotificationsClearAllRequested] event.
  const NotificationsClearAllRequested();
}

final class _NotificationsListBoxChanged extends NotificationsListEvent {
  const _NotificationsListBoxChanged();
}
