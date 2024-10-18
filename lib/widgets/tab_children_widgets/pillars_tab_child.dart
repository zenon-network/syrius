import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class PillarsTabChild extends StatefulWidget {

  const PillarsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<PillarsTabChild> createState() => _PillarsTabChildState();
}

class _PillarsTabChildState extends State<PillarsTabChild> {
  final PillarRewardsHistoryBloc _pillarRewardsHistoryBloc =
      PillarRewardsHistoryBloc();

  @override
  Widget build(BuildContext context) {
    final children = <FluidCell>[
      FluidCell(
        child: PillarRewards(
          pillarRewardsHistoryBloc: _pillarRewardsHistoryBloc,
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
        child: PillarCollect(
          pillarRewardsHistoryBloc: _pillarRewardsHistoryBloc,
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
        child: CreatePillar(
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
        child: PillarListWidget(),
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
    _pillarRewardsHistoryBloc.dispose();
    super.dispose();
  }
}
