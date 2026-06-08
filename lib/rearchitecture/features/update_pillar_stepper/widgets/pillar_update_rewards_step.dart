import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Reward distribution step for updating a pillar.
class PillarUpdateRewardsStep extends StatelessWidget {
  /// Creates a [PillarUpdateRewardsStep].
  const PillarUpdateRewardsStep({
    required this.delegateRewardPercentage,
    required this.momentumRewardPercentage,
    required this.onBackPressed,
    required this.onNextPressed,
    super.key,
  });

  /// Percentage of delegation rewards given to delegators.
  final ValueNotifier<double> delegateRewardPercentage;

  /// Percentage of momentum rewards given to delegators.
  final ValueNotifier<double> momentumRewardPercentage;

  /// Called when the user returns to the previous step.
  final VoidCallback onBackPressed;

  /// Called when the user continues to the submit step.
  final VoidCallback onNextPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ValueListenableBuilder<double>(
          valueListenable: momentumRewardPercentage,
          builder: (_, double value, _) => Column(
            children: <Widget>[
              CustomSlider(
                description: context.l10n.percentageOfMomentumRewards,
                descriptionPosition: SliderDescriptionPosition.top,
                startValue: value,
                min: 0,
                maxValue: 100,
                callback: (double newValue) {
                  momentumRewardPercentage.value = newValue;
                },
              ),
              _RewardSplitLabels(percentage: value),
            ],
          ),
        ),
        kVerticalSpacing,
        ValueListenableBuilder<double>(
          valueListenable: delegateRewardPercentage,
          builder: (_, double value, _) => Column(
            children: <Widget>[
              CustomSlider(
                description: context.l10n.percentageDelegationRewardsGiven,
                descriptionPosition: SliderDescriptionPosition.top,
                startValue: value,
                min: 0,
                maxValue: 100,
                callback: (double newValue) {
                  delegateRewardPercentage.value = newValue;
                },
              ),
              _RewardSplitLabels(percentage: value),
            ],
          ),
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: onBackPressed,
              child: Text(context.l10n.goBack),
            ),
            kHorizontalGap25,
            OutlinedButton(
              onPressed: onNextPressed,
              child: Text(context.l10n.next),
            ),
          ],
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
