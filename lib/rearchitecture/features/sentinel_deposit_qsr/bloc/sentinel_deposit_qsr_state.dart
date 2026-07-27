part of 'sentinel_deposit_qsr_bloc.dart';

/// Base class for all sentinel deposit QSR states.
sealed class SentinelDepositQsrState extends Equatable {
  /// Creates a new [SentinelDepositQsrState].
  const SentinelDepositQsrState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before deposit starts.
final class SentinelDepositQsrInitial extends SentinelDepositQsrState {
  /// Creates a new [SentinelDepositQsrInitial] state.
  const SentinelDepositQsrInitial();
}

/// Failure state emitted when deposit fails.
final class SentinelDepositQsrFailure extends SentinelDepositQsrState {
  /// Creates a new [SentinelDepositQsrFailure] state.
  const SentinelDepositQsrFailure({required this.exception});

  /// The error that caused the deposit operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when deposit completes.
final class SentinelDepositQsrDone extends SentinelDepositQsrState {
  /// Creates a new [SentinelDepositQsrDone] state.
  const SentinelDepositQsrDone();
}

/// Loading state emitted while deposit is in progress.
final class SentinelDepositQsrLoading extends SentinelDepositQsrState {
  /// Creates a new [SentinelDepositQsrLoading] state.
  const SentinelDepositQsrLoading();
}
