part of 'sentinel_deposit_qsr_bloc.dart';

/// Base class for all sentinel deposit QSR events.
sealed class SentinelDepositQsrEvent extends Equatable {
  /// Creates a new [SentinelDepositQsrEvent].
  const SentinelDepositQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests a QSR deposit into the sentinel slot.
final class SentinelDepositQsrRequested extends SentinelDepositQsrEvent {
  /// Creates a new [SentinelDepositQsrRequested] event.
  const SentinelDepositQsrRequested({
    required this.address,
    required this.amount,
  });

  /// The address paying the deposit.
  final Address address;

  /// The amount of QSR to deposit.
  final BigInt amount;

  @override
  List<Object> get props => <Object>[address, amount];
}
