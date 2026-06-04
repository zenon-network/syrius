import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays the Sentinels tab content in a responsive fluid layout.
class SentinelsTabChild extends StatelessWidget {
  /// Creates a Sentinels tab child.
  const SentinelsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  /// Called when the stepper notification asks to show more details.
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    final List<FluidCell> children = <FluidCell>[
      FluidCell(
        child: const SentinelRewardsCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: const SentinelCollectCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: SentinelStatsCard(
          onStepperNotificationSeeMorePressed:
              onStepperNotificationSeeMorePressed,
        ),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      const FluidCell(
        child: SentinelListWidget(),
        width: kStaggeredNumOfColumns,
        height: kStaggeredNumOfColumns / 2,
      ),
    ];

    return StandardFluidLayout(
      children: children,
    );
  }
}
