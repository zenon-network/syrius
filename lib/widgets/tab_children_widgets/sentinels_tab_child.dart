import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SentinelsTabChild extends StatefulWidget {

  const SentinelsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<SentinelsTabChild> createState() => _SentinelsTabChildState();
}

class _SentinelsTabChildState extends State<SentinelsTabChild> {
  final SentinelRewardsHistoryBloc _sentinelRewardsHistoryBloc =
      SentinelRewardsHistoryBloc();

  @override
  Widget build(BuildContext context) {
    final children = <FluidCell>[
      FluidCell(
        child: SentinelRewards(
          sentinelRewardsHistoryBloc: _sentinelRewardsHistoryBloc,
        ),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: SentinelCollect(
          sentinelRewardsHistoryBloc: _sentinelRewardsHistoryBloc,
        ),
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
              widget.onStepperNotificationSeeMorePressed,
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

  @override
  void dispose() {
    _sentinelRewardsHistoryBloc.dispose();
    super.dispose();
  }
}
