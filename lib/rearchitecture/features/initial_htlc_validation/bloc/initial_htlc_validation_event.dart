part of 'initial_htlc_validation_bloc.dart';

/// Base class for initial HTLC validation events.
sealed class InitialHtlcValidationEvent extends Equatable {
  /// Creates an [InitialHtlcValidationEvent].
  const InitialHtlcValidationEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests fetching and validation of an initial HTLC.
final class InitialHtlcValidationRequested extends InitialHtlcValidationEvent {
  /// Creates an [InitialHtlcValidationRequested] event.
  const InitialHtlcValidationRequested({required this._id});

  final Hash _id;

  /// Identifier of the initial HTLC to validate.
  Hash get id => _id;

  @override
  List<Object> get props => <Object>[_id];
}

/// Refreshes the bloc state
final class InitialHtlcValidationRefreshed extends InitialHtlcValidationEvent {
  /// Creates an [InitialHtlcValidationRefreshed] event.
  const InitialHtlcValidationRefreshed();
}
