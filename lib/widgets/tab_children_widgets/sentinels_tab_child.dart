import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SentinelsTabChild extends StatelessWidget {
  const SentinelsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

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
        child: const SentinelCollect(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: CreateSentinel(
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
