part of 'pillar_deposit_qsr_bloc.dart';

/// Base class for all pillar deposit QSR states.
sealed class PillarDepositQsrState extends Equatable {
  /// Creates a new [PillarDepositQsrState].
  const PillarDepositQsrState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before deposit starts.
final class PillarDepositQsrInitial extends PillarDepositQsrState {
  /// Creates a new [PillarDepositQsrInitial] state.
  const PillarDepositQsrInitial();
}

/// Failure state emitted when deposit fails.
final class PillarDepositQsrFailure extends PillarDepositQsrState {
  /// Creates a new [PillarDepositQsrFailure] state.
  const PillarDepositQsrFailure({required this._exception});

  final SyriusException _exception;

  /// The error that caused the deposit operation to fail.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}

/// Success state emitted when deposit completes.
final class PillarDepositQsrDone extends PillarDepositQsrState {
  /// Creates a new [PillarDepositQsrDone] state.
  const PillarDepositQsrDone();
}

/// Loading state emitted while deposit is in progress.
final class PillarDepositQsrLoading extends PillarDepositQsrState {
  /// Creates a new [PillarDepositQsrLoading] state.
  const PillarDepositQsrLoading();
}
