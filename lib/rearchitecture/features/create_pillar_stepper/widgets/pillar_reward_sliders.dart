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
    super.key,
  });

  /// Percentage of delegation rewards given to delegators.
  final ValueNotifier<double> delegateRewardPercentage;

  /// Percentage of momentum rewards given to delegators.
  final ValueNotifier<double> momentumRewardPercentage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ValueListenableBuilder<double>(
          valueListenable: momentumRewardPercentage,
          builder: (BuildContext context, double value, _) {
            return Column(
              children: <Widget>[
                CustomSlider(
                  sliderKey: const Key('pillar_momentum_reward_slider'),
                  description: context.l10n.percentageOfMomentumRewards,
                  descriptionPosition: SliderDescriptionPosition.top,
                  startValue: value,
                  min: 0,
                  maxValue: 100,
                  callback: (double newValue) {
                    momentumRewardPercentage.value = newValue;
                  },
                ),
                _RewardSplitLabels(percentage: momentumRewardPercentage.value),
              ],
            );
          },
        ),
        kVerticalSpacing,
        ValueListenableBuilder<double>(
          valueListenable: delegateRewardPercentage,
          builder: (BuildContext context, double value, _) {
            return Column(
              children: <Widget>[
                CustomSlider(
                  sliderKey: const Key('pillar_delegation_reward_slider'),
                  description: context.l10n.percentageDelegationRewardsGiven,
                  descriptionPosition: SliderDescriptionPosition.top,
                  startValue: value,
                  min: 0,
                  maxValue: 100,
                  callback: (double newValue) {
                    delegateRewardPercentage.value = newValue;
                  },
                ),
                _RewardSplitLabels(percentage: delegateRewardPercentage.value),
              ],
            );
          },
        ),
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
