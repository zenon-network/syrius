part of 'deploy_pillar_bloc.dart';

sealed class DeployPillarState extends Equatable {
  const DeployPillarState();

  @override
  List<Object> get props => <Object>[];
}

final class DeployPillarInitial extends DeployPillarState {
  const DeployPillarInitial();
}

final class DeployPillarFailure extends DeployPillarState {
  const DeployPillarFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class DeployPillarDone extends DeployPillarState {
  const DeployPillarDone();
}

final class DeployPillarLoading extends DeployPillarState {
  const DeployPillarLoading();
}
