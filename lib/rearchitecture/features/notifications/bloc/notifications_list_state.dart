part of 'notifications_list_bloc.dart';

/// Identifies which mutation failed while preserving the displayed list.
enum NotificationsListActionError {
  /// Deleting a single notification failed.
  delete,

  /// Clearing all notifications failed.
  clearAll,
}

/// Base state for [NotificationsListBloc].
sealed class NotificationsListState extends Equatable {
  const NotificationsListState();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Initial state before notifications have been loaded.
final class NotificationsListInitial extends NotificationsListState {
  /// Creates a [NotificationsListInitial] state.
  const NotificationsListInitial();
}

/// Loading state while reading notification history.
final class NotificationsListLoading extends NotificationsListState {
  /// Creates a [NotificationsListLoading] state.
  const NotificationsListLoading();
}

/// Populated state containing the loaded [notifications].
final class NotificationsListPopulated extends NotificationsListState {
  /// Creates a [NotificationsListPopulated] state.
  const NotificationsListPopulated({
    required this.notifications,
    this.actionError,
    this.actionException,
    this.errorNonce = 0,
  });

  /// Stored notifications ordered newest-first.
  final List<StoredWalletNotification> notifications;

  /// Optional mutation error surfaced without discarding the current list.
  final NotificationsListActionError? actionError;

  /// Optional exception associated with [actionError].
  final SyriusException? actionException;

  /// Monotonic counter distinguishing repeated mutation errors.
  final int errorNonce;

  @override
  List<Object?> get props => <Object?>[
    notifications,
    actionError,
    actionException,
    errorNonce,
  ];
}

/// Failure state emitted when loading notifications fails.
final class NotificationsListFailure extends NotificationsListState {
  /// Creates a [NotificationsListFailure] state.
  const NotificationsListFailure({required this.exception});

  /// Mapped error describing the load failure.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
