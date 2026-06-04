part of 'revoke_sentinel_bloc.dart';

/// Base class for all revoke sentinel states.
sealed class RevokeSentinelState extends Equatable {
  /// Creates a new [RevokeSentinelState].
  const RevokeSentinelState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before revocation starts.
final class RevokeSentinelInitial extends RevokeSentinelState {
  /// Creates a new [RevokeSentinelInitial] state.
  const RevokeSentinelInitial();
}

/// Failure state emitted when revocation fails.
final class RevokeSentinelFailure extends RevokeSentinelState {
  /// Creates a new [RevokeSentinelFailure] state.
  const RevokeSentinelFailure({required this.exception});

  /// The error that caused the revocation operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when revocation completes.
final class RevokeSentinelDone extends RevokeSentinelState {
  /// Creates a new [RevokeSentinelDone] state.
  const RevokeSentinelDone();
}

/// Loading state emitted while revocation is in progress.
final class RevokeSentinelLoading extends RevokeSentinelState {
  /// Creates a new [RevokeSentinelLoading] state.
  const RevokeSentinelLoading();
}
