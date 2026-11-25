part of 'pow_generating_status_bloc.dart';

/// Base class for all PoW generating status events.
sealed class PowGeneratingStatusEvent extends Equatable {
  /// Creates a [PowGeneratingStatusEvent].
  const PowGeneratingStatusEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Dispatched when the PoW generation status changes.
final class PowGeneratingStatusChanged extends PowGeneratingStatusEvent {
  /// Creates a [PowGeneratingStatusChanged] event.
  const PowGeneratingStatusChanged(this.status);

  /// The updated PoW generation status.
  final PowStatus status;

  @override
  List<Object> get props => <Object>[status];
}
