part of 'deploy_pillar_bloc.dart';

/// Base class for all deploy pillar events.
sealed class DeployPillarEvent extends Equatable {
  /// Creates a new [DeployPillarEvent].
  const DeployPillarEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests pillar deployment with registration parameters.
final class DeployPillarRequested extends DeployPillarEvent {
  /// Creates a new [DeployPillarRequested] event.
  const DeployPillarRequested({
    required this._blockProducingAddress,
    required this._giveBlockRewardPercentage,
    required this._giveDelegateRewardPercentage,
    required this._pillarName,
    required this._rewardAddress,
  });

  final Address _blockProducingAddress;
  final Address _rewardAddress;
  final String _pillarName;
  final int _giveBlockRewardPercentage;
  final int _giveDelegateRewardPercentage;

  /// Address used to produce blocks.
  Address get blockProducingAddress => _blockProducingAddress;

  /// Address that receives pillar rewards.
  Address get rewardAddress => _rewardAddress;

  /// Name of the pillar being registered.
  String get pillarName => _pillarName;

  /// Percentage of momentum rewards shared.
  int get giveBlockRewardPercentage => _giveBlockRewardPercentage;

  /// Percentage of delegation rewards shared.
  int get giveDelegateRewardPercentage => _giveDelegateRewardPercentage;

  @override
  List<Object> get props => <Object>[
    _blockProducingAddress,
    _giveBlockRewardPercentage,
    _giveDelegateRewardPercentage,
    _pillarName,
    _rewardAddress,
  ];
}
