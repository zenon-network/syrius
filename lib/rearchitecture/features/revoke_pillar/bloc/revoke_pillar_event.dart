part of 'revoke_pillar_bloc.dart';

/// Base class for all revoke pillar events.
sealed class RevokePillarEvent extends Equatable {
  /// Creates a new [RevokePillarEvent].
  const RevokePillarEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests revocation of a pillar.
final class RevokePillarRequested extends RevokePillarEvent {
  /// Creates a new [RevokePillarRequested] event.
  const RevokePillarRequested({
    required this._pillarName,
  });

  final String _pillarName;

  /// Name of the pillar to revoke.
  String get pillarName => _pillarName;

  @override
  List<Object> get props => <Object>[_pillarName];
}
