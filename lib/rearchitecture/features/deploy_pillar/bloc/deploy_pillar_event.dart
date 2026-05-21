part of 'deploy_pillar_bloc.dart';

sealed class DeployPillarEvent extends Equatable {
  const DeployPillarEvent();

  @override
  List<Object> get props => <Object>[];
}

final class DeployPillarRequested extends DeployPillarEvent {
  const DeployPillarRequested({
    required this.blockProducingAddress,
    required this.giveBlockRewardPercentage,
    required this.giveDelegateRewardPercentage,
    required this.pillarName,
    required this.rewardAddress,
  });

  final Address blockProducingAddress;
  final Address rewardAddress;
  final String pillarName;
  final int giveBlockRewardPercentage;
  final int giveDelegateRewardPercentage;

  @override
  List<Object> get props => <Object>[
    blockProducingAddress,
    giveBlockRewardPercentage,
    giveDelegateRewardPercentage,
    pillarName,
    rewardAddress,
  ];
}
