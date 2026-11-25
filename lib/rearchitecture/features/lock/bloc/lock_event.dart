part of 'lock_bloc.dart';

/// Base class for lock navigation and inactivity timer events.
sealed class LockEvent extends Equatable {
  /// Creates a [LockEvent].
  const LockEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Starts the auto-lock inactivity countdown.
final class LockCountDownRequested extends LockEvent {
  /// Creates a [LockCountDownRequested] event.
  const LockCountDownRequested();
}

/// Requests navigating to the lock tab and locking the wallet.
final class LockNavigateToLockRequested extends LockEvent {
  /// Creates a [LockNavigateToLockRequested] event.
  const LockNavigateToLockRequested();
}

/// Resets the auto-lock inactivity timer on user activity.
final class LockTimerResetRequested extends LockEvent {
  /// Creates a [LockTimerResetRequested] event.
  const LockTimerResetRequested();
}

/// Requests navigating to the dashboard tab after initial wallet unlock.
final class LockNavigateToDashboardRequested extends LockEvent {
  /// Creates a [LockNavigateToDashboardRequested] event.
  const LockNavigateToDashboardRequested();
}

/// Requests returning to the previously active tab after unlocking.
final class LockNavigateToPreviousTabRequested extends LockEvent {
  /// Creates a [LockNavigateToPreviousTabRequested] event.
  const LockNavigateToPreviousTabRequested();
}
