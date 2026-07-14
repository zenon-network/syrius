part of 'deploy_pillar_bloc.dart';

// Keep state fields private while exposing public constructor parameters.
// ignore_for_file: prefer_initializing_formals

/// Base class for all deploy pillar states.
sealed class DeployPillarState extends Equatable {
  /// Creates a new [DeployPillarState].
  const DeployPillarState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before deployment starts.
final class DeployPillarInitial extends DeployPillarState {
  /// Creates a new [DeployPillarInitial] state.
  const DeployPillarInitial();
}

/// Failure state emitted when deployment fails.
final class DeployPillarFailure extends DeployPillarState {
  /// Creates a new [DeployPillarFailure] state.
  const DeployPillarFailure({required this._exception});

  final SyriusException _exception;

  /// The error that caused the deployment operation to fail.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}

/// Success state emitted when deployment finishes.
final class DeployPillarDone extends DeployPillarState {
  /// Creates a new [DeployPillarDone] state.
  const DeployPillarDone({required AccountBlockTemplate accountBlock})
    : _accountBlock = accountBlock;

  final AccountBlockTemplate _accountBlock;

  /// The published account block returned by the node.
  AccountBlockTemplate get accountBlock => _accountBlock;

  @override
  List<Object> get props => <Object>[_accountBlock];
}

/// Loading state emitted while deployment is in progress.
final class DeployPillarLoading extends DeployPillarState {
  /// Creates a new [DeployPillarLoading] state.
  const DeployPillarLoading();
}
