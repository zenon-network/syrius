part of 'update_pillar_bloc.dart';

sealed class UpdatePillarEvent extends Equatable {
  const UpdatePillarEvent();

  @override
  List<Object> get props => <Object>[];
}

final class UpdatePillarRequested extends UpdatePillarEvent {
  const UpdatePillarRequested({
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
