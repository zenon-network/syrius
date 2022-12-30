import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/create_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillar_collect.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillar_rewards.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillars_list_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/standard_fluid_layout.dart';

class PillarsTabChild extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const PillarsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State<PillarsTabChild> createState() => _PillarsTabChildState();
}

class _PillarsTabChildState extends State<PillarsTabChild> {
  final PillarRewardsHistoryBloc _pillarRewardsHistoryBloc =
      PillarRewardsHistoryBloc();

  @override
  Widget build(BuildContext context) {
    final List<FluidCell> children = [
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
        child: PillarsListWidget(),
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
