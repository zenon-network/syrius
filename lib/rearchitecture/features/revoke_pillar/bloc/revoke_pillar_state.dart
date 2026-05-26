part of 'revoke_pillar_bloc.dart';

sealed class RevokePillarState extends Equatable {
  const RevokePillarState();

  @override
  List<Object> get props => <Object>[];
}

final class RevokePillarInitial extends RevokePillarState {
  const RevokePillarInitial();
}

final class RevokePillarFailure extends RevokePillarState {
  const RevokePillarFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class RevokePillarDone extends RevokePillarState {
  const RevokePillarDone();
}

final class RevokePillarLoading extends RevokePillarState {
  const RevokePillarLoading();
}
