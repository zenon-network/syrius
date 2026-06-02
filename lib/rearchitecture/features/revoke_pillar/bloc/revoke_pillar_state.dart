part of 'revoke_pillar_bloc.dart';

/// Base class for all revoke pillar states.
sealed class RevokePillarState extends Equatable {
  /// Creates a new [RevokePillarState].
  const RevokePillarState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before revocation starts.
final class RevokePillarInitial extends RevokePillarState {
  /// Creates a new [RevokePillarInitial] state.
  const RevokePillarInitial();
}

/// Failure state emitted when revocation fails.
final class RevokePillarFailure extends RevokePillarState {
  /// Creates a new [RevokePillarFailure] state.
  const RevokePillarFailure({required this._exception});

  final SyriusException _exception;

  /// The error that caused the revocation operation to fail.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}

/// Success state emitted when revocation completes.
final class RevokePillarDone extends RevokePillarState {
  /// Creates a new [RevokePillarDone] state.
  const RevokePillarDone();
}

/// Loading state emitted while revocation is in progress.
final class RevokePillarLoading extends RevokePillarState {
  /// Creates a new [RevokePillarLoading] state.
  const RevokePillarLoading();
}
