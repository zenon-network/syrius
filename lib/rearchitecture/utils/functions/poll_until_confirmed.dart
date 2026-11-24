import 'dart:async';

/// Default interval between on-chain confirmation checks.
const Duration kDefaultConfirmationPollInterval = Duration(seconds: 2);

/// Default maximum duration to wait for on-chain confirmation before falling
/// back to refreshing UI state.
const Duration kDefaultConfirmationTimeout = Duration(seconds: 75);

/// Polls [fetch] every [pollInterval] until [isConfirmed] returns `true`,
/// [timeout] elapses, or [isCancelled] returns `true`.
///
/// Transient errors from [fetch] are swallowed while polling so an already
/// submitted on-chain transaction is not reported as failed due to a
/// temporary RPC hiccup. Returns `true` if confirmation was observed before
/// [timeout] or cancellation, and `false` otherwise.
Future<bool> pollUntilConfirmed<T>({
  required Future<T> Function() fetch,
  required bool Function(T value) isConfirmed,
  Duration pollInterval = kDefaultConfirmationPollInterval,
  Duration timeout = kDefaultConfirmationTimeout,
  bool Function()? isCancelled,
  DateTime Function()? now,
  Future<void> Function(Duration duration)? delay,
}) async {
  final DateTime Function() clock = now ?? DateTime.now;
  final Future<void> Function(Duration duration) sleep =
      delay ?? Future<void>.delayed;
  final DateTime deadline = clock().add(timeout);

  while (!(isCancelled?.call() ?? false)) {
    try {
      final T value = await fetch();
      if (isConfirmed(value)) {
        return true;
      }
    } on Object {
      // Ignore transient RPC errors while waiting for on-chain confirmation.
    }

    if (isCancelled?.call() ?? false) {
      return false;
    }

    final Duration remaining = deadline.difference(clock());
    if (remaining <= Duration.zero) {
      return false;
    }

    final Duration sleepDuration = remaining < pollInterval
        ? remaining
        : pollInterval;
    await sleep(sleepDuration.isNegative ? Duration.zero : sleepDuration);
  }

  return false;
}
