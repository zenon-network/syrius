part of 'pillar_withdraw_qsr_bloc.dart';

/// Base class for all pillar withdraw QSR events.
sealed class PillarWithdrawQsrEvent extends Equatable {
  /// Creates a new [PillarWithdrawQsrEvent].
  const PillarWithdrawQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests a QSR withdrawal from the pillar slot.
final class PillarWithdrawQsrRequested extends PillarWithdrawQsrEvent {
  /// Creates a new [PillarWithdrawQsrRequested] event.
  const PillarWithdrawQsrRequested({required this._address});

  final Address _address;

  /// The address receiving the withdrawal.
  Address get address => _address;

  @override
  List<Object> get props => <Object>[_address];
}
