part of 'auto_receive_tx_worker.dart';

/// State emitted by [AutoReceiveTxWorker].
final class AutoReceiveTxState extends Equatable {
  /// Creates an [AutoReceiveTxState].
  const AutoReceiveTxState({
    this.isRunning = false,
    this.pendingCount = 0,
    this.lastNotification,
    this.notificationSequence = 0,
  });

  /// Whether the worker is currently receiving a transaction.
  final bool isRunning;

  /// Number of queued unreceived block hashes awaiting processing.
  final int pendingCount;

  /// Notification emitted by the latest receive outcome, if any.
  final WalletNotification? lastNotification;

  /// Monotonic counter incremented on every emitted notification so
  /// identical notifications are never deduplicated.
  final int notificationSequence;

  @override
  List<Object?> get props => <Object?>[
    isRunning,
    pendingCount,
    lastNotification,
    notificationSequence,
  ];
}
