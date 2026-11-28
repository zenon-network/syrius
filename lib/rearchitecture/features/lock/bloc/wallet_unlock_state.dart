part of 'wallet_unlock_bloc.dart';

/// Lifecycle status for [WalletUnlockBloc].
enum WalletUnlockStatus {
  /// Idle, waiting for password entry.
  initial,

  /// Decrypting the wallet file.
  decrypting,

  /// Initializing wallet addresses, WebSocket, and storage after first unlock.
  initializing,

  /// Wallet unlocked successfully.
  success,

  /// Unlock attempt failed with remaining attempts available.
  failure,

  /// Failed unlock attempts reached the auto-erase threshold.
  autoEraseTriggered,
}

/// State emitted by [WalletUnlockBloc].
final class WalletUnlockState extends Equatable {
  /// Creates a [WalletUnlockState].
  const WalletUnlockState({
    required this.remainingAttempts,
    this.status = WalletUnlockStatus.initial,
    this.autoEraseEnabled = true,
    this.nonce = 0,
  });

  /// Current unlock lifecycle status.
  final WalletUnlockStatus status;

  /// Number of unlock attempts remaining before wallet auto-erase.
  final int remainingAttempts;

  /// Whether automatic wallet erasure after failed attempts is enabled.
  final bool autoEraseEnabled;

  /// Monotonic counter so repeated status transitions (such as consecutive
  /// failures) trigger UI listeners.
  final int nonce;

  /// Whether an unlock operation is currently in progress.
  bool get isBusy =>
      status == WalletUnlockStatus.decrypting ||
      status == WalletUnlockStatus.initializing;

  @override
  List<Object> get props => <Object>[
    status,
    remainingAttempts,
    autoEraseEnabled,
    nonce,
  ];
}
