import 'dart:async';

/// Default interval between on-chain confirmation checks.
const Duration kDefaultConfirmationPollInterval = Duration(seconds: 2);

/// Default maximum duration to wait for on-chain confirmation before falling
/// back to refreshing UI state.
const Duration kDefaultConfirmationTimeout = Duration(seconds: 75);

/// Default timeout for a pre-transaction on-chain state snapshot read.
const Duration kDefaultSnapshotReadTimeout = Duration(seconds: 10);

class _PollDeadlineExceeded implements Exception {
  const _PollDeadlineExceeded();
}

/// Polls [fetch] every [pollInterval] until [isConfirmed] returns `true`,
/// [timeout] elapses, or [isCancelled] returns `true`.
///
/// Each [fetch] call is bounded by the remaining [timeout] budget so a stalled
/// RPC cannot outlive [timeout]. Transient errors from [fetch] are swallowed
/// while polling so an already submitted on-chain transaction is not reported
/// as failed due to a temporary RPC hiccup. Returns `true` if confirmation was
/// observed before [timeout] or cancellation, and `false` otherwise.
Future<bool> pollUntilConfirmed<T>({
  required Future<T> Function() fetch,
  required bool Function(T value) isConfirmed,
  Duration pollInterval = kDefaultConfirmationPollInterval,
  Duration timeout = kDefaultConfirmationTimeout,
  bool Function()? isCancelled,
  DateTime Function()? now,
  Future<void> Function(Duration duration)? delay,
}) async {
  assert(!pollInterval.isNegative, 'pollInterval must not be negative');
  assert(!timeout.isNegative, 'timeout must not be negative');

  final DateTime Function() clock = now ?? DateTime.now;
  final Future<void> Function(Duration duration) sleep =
      delay ?? Future<void>.delayed;
  final Duration effectivePollInterval = pollInterval.isNegative
      ? Duration.zero
      : pollInterval;
  final DateTime deadline = clock().add(timeout);

  while (!(isCancelled?.call() ?? false)) {
    final Duration remainingBeforeFetch = deadline.difference(clock());
    if (remainingBeforeFetch <= Duration.zero) {
      return false;
    }

    T? value;
    bool hasValue = false;
    try {
      value = await fetch().timeout(
        remainingBeforeFetch,
        onTimeout: () => throw const _PollDeadlineExceeded(),
      );
      hasValue = true;
    } on _PollDeadlineExceeded {
      return false;
    } on Object {
      // Ignore transient RPC errors while waiting for on-chain confirmation.
    }

    if (hasValue && isConfirmed(value as T)) {
      return true;
    }

    if (isCancelled?.call() ?? false) {
      return false;
    }

    final Duration remainingAfterFetch = deadline.difference(clock());
    if (remainingAfterFetch <= Duration.zero ||
        remainingAfterFetch <= effectivePollInterval) {
      return false;
    }

    await sleep(effectivePollInterval);
  }

  return false;
}
