part of 'pillar_deposit_qsr_bloc.dart';

/// Base class for all pillar deposit QSR events.
sealed class PillarDepositQsrEvent extends Equatable {
  /// Creates a new [PillarDepositQsrEvent].
  const PillarDepositQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests a QSR deposit into the pillar slot.
final class PillarDepositQsrRequested extends PillarDepositQsrEvent {
  /// Creates a new [PillarDepositQsrRequested] event.
  const PillarDepositQsrRequested({
    required Address address,
    required BigInt amount,
  }) : _address = address,
       _amount = amount;

  final Address _address;
  final BigInt _amount;

  /// The address paying the deposit.
  Address get address => _address;

  /// The amount of QSR to deposit.
  BigInt get amount => _amount;

  @override
  List<Object> get props => <Object>[_address, _amount];
}
