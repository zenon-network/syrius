import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/plasma/plasma_stats_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/balance.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/delegation_stats.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/dual_coin_stats.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/plasma_stats.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/realtime_statistics.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/sentinels.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/staking.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/swap_decay.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/total_hourly_transactions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/dashboard_widgets/transfer.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/transfer_widgets/latest_transactions/latest_transactions_transfer_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/standard_fluid_layout.dart';

class DashboardTabChild extends StatefulWidget {
  final void Function(
    Tabs, {
    bool redirectWithSendContainerLarge,
    bool redirectWithReceiveContainerLarge,
  })? changePage;

  const DashboardTabChild({Key? key, this.changePage}) : super(key: key);

  @override
  _DashboardTabChildState createState() => _DashboardTabChildState();
}

class _DashboardTabChildState extends State<DashboardTabChild> {
  @override
  void initState() {
    super.initState();
    sl.get<PlasmaStatsBloc>().getPlasmas();
  }

  @override
  Widget build(BuildContext context) {
    return _getFluidLayout();
  }

  Widget _getFluidLayout() {
    final int defaultCellWidth = context.layout.value(
      xl: kStaggeredNumOfColumns ~/ 6,
      lg: kStaggeredNumOfColumns ~/ 6,
      md: kStaggeredNumOfColumns ~/ 6,
      sm: kStaggeredNumOfColumns ~/ 4,
      xs: kStaggeredNumOfColumns ~/ 2,
    );

    final List<FluidCell> children = [
      const FluidCell(
        child: DualCoinStats(),
      ),
      const FluidCell(
        child: PlasmaStats(),
      ),
      FluidCell(
        child: Transfer(
          changePage: widget.changePage,
        ),
      ),
      const FluidCell(
        child: TotalHourlyTransactions(),
        height: kStaggeredNumOfColumns / 8,
      ),
      const FluidCell(
        child: Pillars(),
        height: kStaggeredNumOfColumns / 8,
      ),
      const FluidCell(
        child: Staking(),
        height: kStaggeredNumOfColumns / 8,
      ),
      const FluidCell(
        child: SwapDecay(),
        height: kStaggeredNumOfColumns / 8,
      ),
      const FluidCell(
        child: DelegationStats(),
        height: kStaggeredNumOfColumns / 8,
      ),
      FluidCell(
        child: const Sentinels(),
        width: defaultCellWidth,
        height: kStaggeredNumOfColumns / 8,
      ),
      FluidCell(
        child: const BalanceWidget(),
        width: defaultCellWidth * 2,
      ),
      FluidCell(
        child: const RealtimeStatistics(),
        width: defaultCellWidth * 2,
      ),
      FluidCell(
        child: const LatestTransactions(
          version: LatestTransactionsVersion.dashboard,
        ),
        width: defaultCellWidth * 2,
      ),
    ];

    return StandardFluidLayout(
      defaultCellWidth: defaultCellWidth,
      defaultCellHeight: kStaggeredNumOfColumns / 4,
      children: children,
    );
  }
}
