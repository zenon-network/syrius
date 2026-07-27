part of 'deploy_sentinel_bloc.dart';

/// Base class for all deploy sentinel events.
sealed class DeploySentinelEvent extends Equatable {
  /// Creates a new [DeploySentinelEvent].
  const DeploySentinelEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests sentinel deployment.
final class DeploySentinelRequested extends DeploySentinelEvent {
  /// Creates a new [DeploySentinelRequested] event.
  const DeploySentinelRequested();
}
