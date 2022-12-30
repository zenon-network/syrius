import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/sentinel_widgets/create_sentinel.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/sentinel_widgets/sentinel_collect.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/sentinel_widgets/sentinel_rewards.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/sentinel_widgets/sentinels_list_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/standard_fluid_layout.dart';

class SentinelsTabChild extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const SentinelsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State<SentinelsTabChild> createState() => _SentinelsTabChildState();
}

class _SentinelsTabChildState extends State<SentinelsTabChild> {
  final SentinelRewardsHistoryBloc _sentinelRewardsHistoryBloc =
      SentinelRewardsHistoryBloc();

  @override
  Widget build(BuildContext context) {
    final List<FluidCell> children = [
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
        child: SentinelsListWidget(),
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
