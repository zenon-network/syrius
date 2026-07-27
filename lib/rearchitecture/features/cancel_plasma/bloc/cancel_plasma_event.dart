part of 'cancel_plasma_bloc.dart';

/// Base class for all cancel Plasma events.
sealed class CancelPlasmaEvent extends Equatable {
  /// Creates a new [CancelPlasmaEvent].
  const CancelPlasmaEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests cancellation of a revocable Plasma fusion.
final class CancelPlasmaRequested extends CancelPlasmaEvent {
  /// Creates a new [CancelPlasmaRequested] event.
  const CancelPlasmaRequested({required this.plasmaHash});

  /// Hash of the Plasma fusion entry that should be cancelled.
  final Hash plasmaHash;

  @override
  List<Object> get props => <Object>[plasmaHash];
}
