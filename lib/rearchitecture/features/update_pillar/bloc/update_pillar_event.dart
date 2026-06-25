part of 'update_pillar_bloc.dart';

/// Base class for all update pillar events.
sealed class UpdatePillarEvent extends Equatable {
  /// Creates a new [UpdatePillarEvent].
  const UpdatePillarEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests a pillar update transaction with the provided registration details.
final class UpdatePillarRequested extends UpdatePillarEvent {
  /// Creates a new [UpdatePillarRequested] event.
  const UpdatePillarRequested({
    required this.blockProducingAddress,
    required this.giveBlockRewardPercentage,
    required this.giveDelegateRewardPercentage,
    required this.pillarName,
    required this.rewardAddress,
  });

  /// Address used by the pillar to produce blocks.
  final Address blockProducingAddress;

  /// Address that receives pillar rewards.
  final Address rewardAddress;

  /// Name of the pillar being updated.
  final String pillarName;

  /// Percentage of block rewards shared.
  final int giveBlockRewardPercentage;

  /// Percentage of delegation rewards shared.
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
