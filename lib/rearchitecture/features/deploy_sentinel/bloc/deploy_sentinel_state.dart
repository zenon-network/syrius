part of 'deploy_sentinel_bloc.dart';

/// Base class for all deploy sentinel states.
sealed class DeploySentinelState extends Equatable {
  /// Creates a new [DeploySentinelState].
  const DeploySentinelState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before deployment starts.
final class DeploySentinelInitial extends DeploySentinelState {
  /// Creates a new [DeploySentinelInitial] state.
  const DeploySentinelInitial();
}

/// Failure state emitted when deployment fails.
final class DeploySentinelFailure extends DeploySentinelState {
  /// Creates a new [DeploySentinelFailure] state.
  const DeploySentinelFailure({required this.exception});

  /// The error that caused the deployment operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when deployment finishes.
final class DeploySentinelDone extends DeploySentinelState {
  /// Creates a new [DeploySentinelDone] state.
  const DeploySentinelDone();
}

/// Loading state emitted while deployment is in progress.
final class DeploySentinelLoading extends DeploySentinelState {
  /// Creates a new [DeploySentinelLoading] state.
  const DeploySentinelLoading();
}
