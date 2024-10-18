import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class StakingTabChild extends StatefulWidget {
  const StakingTabChild({super.key});

  @override
  State createState() {
    return _StakingTabChildState();
  }
}

class _StakingTabChildState extends State<StakingTabChild> {
  final StakingListBloc _stakingListBloc = StakingListBloc();
  final StakingRewardsHistoryBloc _stakingRewardsHistoryBloc =
      StakingRewardsHistoryBloc();

  @override
  Widget build(BuildContext context) {
    return _getFluidLayout();
  }

  Widget _getFluidLayout() {
    final children = <FluidCell>[
      FluidCell(
        child: StakingRewards(
          stakingRewardsHistoryBloc: _stakingRewardsHistoryBloc,
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
        child: StakeCollect(
          stakingRewardsHistoryBloc: _stakingRewardsHistoryBloc,
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
        child: Consumer<SelectedAddressNotifier>(
          builder: (_, __, child) => StakingOptions(_stakingListBloc),
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
    _stakingRewardsHistoryBloc.dispose();
    super.dispose();
  }
}
