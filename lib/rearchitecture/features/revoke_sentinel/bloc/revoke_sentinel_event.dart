part of 'revoke_sentinel_bloc.dart';

/// Base class for all revoke sentinel events.
sealed class RevokeSentinelEvent extends Equatable {
  /// Creates a new [RevokeSentinelEvent].
  const RevokeSentinelEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests revocation of a sentinel.
final class RevokeSentinelRequested extends RevokeSentinelEvent {
  /// Creates a new [RevokeSentinelRequested] event.
  const RevokeSentinelRequested();
}
