part of 'revoke_pillar_bloc.dart';

sealed class RevokePillarEvent extends Equatable {
  const RevokePillarEvent();

  @override
  List<Object> get props => <Object>[];
}

final class RevokePillarRequested extends RevokePillarEvent {
  const RevokePillarRequested({
    required  this.pillarName,
  });

  final String pillarName;

  @override
  List<Object> get props => <Object>[pillarName];
}
