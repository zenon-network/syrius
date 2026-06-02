part of 'delegation_bloc.dart';

/// Base class for all delegation events.
sealed class DelegationEvent extends Equatable {
  /// Creates a new [DelegationEvent].
  const DelegationEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests a delegation transaction for a specific pillar.
final class DelegationRequested extends DelegationEvent {
  /// Creates a new [DelegationRequested] event.
  const DelegationRequested({
    required this._address,
    required this._pillarName,
  });

  final Address _address;
  final String _pillarName;

  /// The delegator address.
  Address get address => _address;

  /// The target pillar name.
  String get pillarName => _pillarName;

  @override
  List<Object> get props => <Object>[_address, _pillarName];
}
