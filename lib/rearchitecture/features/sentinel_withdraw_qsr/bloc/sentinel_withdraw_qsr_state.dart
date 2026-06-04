part of 'sentinel_withdraw_qsr_bloc.dart';

/// Base class for all sentinel withdraw QSR states.
sealed class SentinelWithdrawQsrState extends Equatable {
  /// Creates a new [SentinelWithdrawQsrState].
  const SentinelWithdrawQsrState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before withdrawal starts.
final class SentinelWithdrawQsrInitial extends SentinelWithdrawQsrState {
  /// Creates a new [SentinelWithdrawQsrInitial] state.
  const SentinelWithdrawQsrInitial();
}

/// Failure state emitted when withdrawal fails.
final class SentinelWithdrawQsrFailure extends SentinelWithdrawQsrState {
  /// Creates a new [SentinelWithdrawQsrFailure] state.
  const SentinelWithdrawQsrFailure({required this.exception});

  /// The error that caused the withdrawal operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when withdrawal completes.
final class SentinelWithdrawQsrPopulated extends SentinelWithdrawQsrState {
  /// Creates a new [SentinelWithdrawQsrPopulated] state.
  const SentinelWithdrawQsrPopulated();
}

/// Loading state emitted while withdrawal is in progress.
final class SentinelWithdrawQsrLoading extends SentinelWithdrawQsrState {
  /// Creates a new [SentinelWithdrawQsrLoading] state.
  const SentinelWithdrawQsrLoading();
}
