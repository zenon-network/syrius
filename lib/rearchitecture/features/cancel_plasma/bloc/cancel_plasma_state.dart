part of 'cancel_plasma_bloc.dart';

/// Base class for all cancel Plasma states.
sealed class CancelPlasmaState extends Equatable {
  /// Creates a new [CancelPlasmaState].
  const CancelPlasmaState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before Plasma cancellation starts.
final class CancelPlasmaInitial extends CancelPlasmaState {
  /// Creates a new [CancelPlasmaInitial] state.
  const CancelPlasmaInitial();
}

/// Failure state emitted when Plasma cancellation fails.
final class CancelPlasmaFailure extends CancelPlasmaState {
  /// Creates a new [CancelPlasmaFailure] state.
  const CancelPlasmaFailure({required this.exception});

  /// The error that caused the cancellation operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when Plasma cancellation completes.
final class CancelPlasmaDone extends CancelPlasmaState {
  /// Creates a new [CancelPlasmaDone] state.
  const CancelPlasmaDone();
}

/// Loading state emitted while Plasma cancellation is in progress.
final class CancelPlasmaLoading extends CancelPlasmaState {
  /// Creates a new [CancelPlasmaLoading] state.
  const CancelPlasmaLoading();
}
