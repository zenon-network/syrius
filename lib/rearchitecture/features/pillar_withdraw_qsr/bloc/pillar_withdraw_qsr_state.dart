part of 'pillar_withdraw_qsr_bloc.dart';

/// Base class for all pillar withdraw QSR states.
sealed class PillarWithdrawQsrState extends Equatable {
  /// Creates a new [PillarWithdrawQsrState].
  const PillarWithdrawQsrState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before withdrawal starts.
final class PillarWithdrawQsrInitial extends PillarWithdrawQsrState {
  /// Creates a new [PillarWithdrawQsrInitial] state.
  const PillarWithdrawQsrInitial();
}

/// Failure state emitted when withdrawal fails.
final class PillarWithdrawQsrFailure extends PillarWithdrawQsrState {
  /// Creates a new [PillarWithdrawQsrFailure] state.
  const PillarWithdrawQsrFailure({required this._exception});

  final SyriusException _exception;

  /// The error that caused the withdrawal operation to fail.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}

/// Success state emitted when withdrawal completes.
final class PillarWithdrawQsrPopulated extends PillarWithdrawQsrState {
  /// Creates a new [PillarWithdrawQsrPopulated] state.
  const PillarWithdrawQsrPopulated();
}

/// Loading state emitted while withdrawal is in progress.
final class PillarWithdrawQsrLoading extends PillarWithdrawQsrState {
  /// Creates a new [PillarWithdrawQsrLoading] state.
  const PillarWithdrawQsrLoading();
}
