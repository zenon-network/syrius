part of 'lock_bloc.dart';

/// Action emitted by [LockBloc] for the application shell to perform.
enum LockAction {
  /// Initial idle state.
  initial,

  /// Start the auto-lock inactivity countdown.
  countDown,

  /// Lock the wallet and switch to the lock tab.
  navigateToLock,

  /// Reset the active auto-lock timer.
  resetTimer,

  /// Switch to the dashboard tab.
  navigateToDashboard,

  /// Switch back to the tab that was open prior to locking.
  navigateToPreviousTab,
}

/// State emitted by [LockBloc].
final class WalletLockState extends Equatable {
  /// Creates a [WalletLockState].
  const WalletLockState({this.action = LockAction.initial, this.sequence = 0});

  /// Latest lock action to handle.
  final LockAction action;

  /// Monotonic counter ensuring repeated identical actions (such as
  /// [LockAction.resetTimer]) are not deduplicated.
  final int sequence;

  @override
  List<Object> get props => <Object>[action, sequence];
}
