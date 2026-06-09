import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Tab content for staking-related cards and lists.
class StakingTabChild extends StatefulWidget {
  /// Creates a staking tab child.
  const StakingTabChild({super.key});

  @override
  State<StakingTabChild> createState() {
    return _StakingTabChildState();
  }
}

class _StakingTabChildState extends State<StakingTabChild> {
  final StakingListBloc _stakingListBloc = StakingListBloc();

  @override
  Widget build(BuildContext context) {
    return _getFluidLayout();
  }

  Widget _getFluidLayout() {
    final List<FluidCell> children = <FluidCell>[
      FluidCell(
        child: const StakingRewardsCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: const StakeCollectCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: StakingOptionsCard(
          onStakeCreated: _stakingListBloc.refreshResults,
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
        child: StakingList(_stakingListBloc),
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
    _stakingListBloc.dispose();
    super.dispose();
  }
}
