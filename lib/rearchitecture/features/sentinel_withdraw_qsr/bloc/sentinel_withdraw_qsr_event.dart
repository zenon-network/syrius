part of 'sentinel_withdraw_qsr_bloc.dart';

/// Base class for all sentinel withdraw QSR events.
sealed class SentinelWithdrawQsrEvent extends Equatable {
  /// Creates a new [SentinelWithdrawQsrEvent].
  const SentinelWithdrawQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests a QSR withdrawal from the sentinel slot.
final class SentinelWithdrawQsrRequested extends SentinelWithdrawQsrEvent {
  /// Creates a new [SentinelWithdrawQsrRequested] event.
  const SentinelWithdrawQsrRequested({required this.address});

  /// The address receiving the withdrawal.
  final Address address;

  @override
  List<Object> get props => <Object>[address];
}
