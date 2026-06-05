import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Reward distribution sliders for pillar registration.
class PillarRewardSliders extends StatelessWidget {
  /// Creates [PillarRewardSliders].
  const PillarRewardSliders({
    required this.delegateRewardPercentage,
    required this.momentumRewardPercentage,
    required this.onDelegateRewardChanged,
    required this.onMomentumRewardChanged,
    super.key,
  });

  /// Percentage of delegation rewards given to delegators.
  final double delegateRewardPercentage;

  /// Percentage of momentum rewards given to delegators.
  final double momentumRewardPercentage;

  /// Called when the delegation reward percentage changes.
  final ValueChanged<double> onDelegateRewardChanged;

  /// Called when the momentum reward percentage changes.
  final ValueChanged<double> onMomentumRewardChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CustomSlider(
          description: context.l10n.percentageOfMomentumRewards,
          descriptionPosition: SliderDescriptionPosition.top,
          startValue: momentumRewardPercentage,
          min: 0,
          maxValue: 100,
          callback: onMomentumRewardChanged,
        ),
        _RewardSplitLabels(percentage: momentumRewardPercentage),
        kVerticalSpacing,
        CustomSlider(
          description: context.l10n.percentageDelegationRewardsGiven,
          descriptionPosition: SliderDescriptionPosition.top,
          startValue: delegateRewardPercentage,
          min: 0,
          maxValue: 100,
          callback: onDelegateRewardChanged,
        ),
        _RewardSplitLabels(percentage: delegateRewardPercentage),
      ],
    );
  }
}

class _RewardSplitLabels extends StatelessWidget {
  const _RewardSplitLabels({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          context.l10n.pillarsWithNumber(100 - percentage.toInt()),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          context.l10n.delegators(percentage.toInt()),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
