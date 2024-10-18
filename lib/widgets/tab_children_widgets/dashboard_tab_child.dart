import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class DashboardTabChild extends StatefulWidget {

  const DashboardTabChild({super.key, this.changePage});
  final void Function(
    Tabs, {
    bool redirectWithSendContainerLarge,
    bool redirectWithReceiveContainerLarge,
  })? changePage;

  @override
  State<DashboardTabChild> createState() => _DashboardTabChildState();
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
    final defaultCellWidth = context.layout.value(
      xl: kStaggeredNumOfColumns ~/ 6,
      lg: kStaggeredNumOfColumns ~/ 6,
      md: kStaggeredNumOfColumns ~/ 6,
      sm: kStaggeredNumOfColumns ~/ 4,
      xs: kStaggeredNumOfColumns ~/ 2,
    );

    final children = <FluidCell>[
      const FluidCell(
        child: DualCoinStatsCard(),
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
        height: kStaggeredNumOfColumns / 4,
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
        child: DelegationCard(),
        height: kStaggeredNumOfColumns / 8,
      ),
      const FluidCell(
        child: Sentinels(),
        height: kStaggeredNumOfColumns / 8,
      ),
      FluidCell(
        child: const BalanceCard(),
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
      children: children,
    );
  }
}
