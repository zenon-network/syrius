import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/staking/staking_list_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/staking/staking_rewards_history_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/staking_widgets/stake_collect.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/staking_widgets/staking_list/staking_list.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/staking_widgets/staking_options/staking_options.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/staking_widgets/staking_rewards.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/standard_fluid_layout.dart';

class StakingTabChild extends StatefulWidget {
  const StakingTabChild({Key? key}) : super(key: key);

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
    final List<FluidCell> children = [
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
