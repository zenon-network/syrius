import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SettingsTabChild extends StatefulWidget {

  const SettingsTabChild(
    this._onChangeAutoLockTime, {
    required this.onStepperNotificationSeeMorePressed,
    required this.onNodeChangedCallback,
    super.key,
  });
  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback onStepperNotificationSeeMorePressed;
  final VoidCallback onNodeChangedCallback;

  @override
  State<SettingsTabChild> createState() => _SettingsTabChildState();
}

class _SettingsTabChildState extends State<SettingsTabChild> {
  final AccountChainStatsBloc _accountChainStatsBloc = AccountChainStatsBloc();

  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      defaultCellWidth: context.layout.value(
        xl: kStaggeredNumOfColumns ~/ 4,
        lg: kStaggeredNumOfColumns ~/ 4,
        md: kStaggeredNumOfColumns ~/ 4,
        sm: kStaggeredNumOfColumns,
        xs: kStaggeredNumOfColumns,
      ),
      children: [
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 2,
            lg: kStaggeredNumOfColumns ~/ 2,
            md: kStaggeredNumOfColumns ~/ 2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: Addresses(
            accountChainStatsBloc: _accountChainStatsBloc,
          ),
        ),
        const FluidCell(
          child: GeneralWidget(),
        ),
        FluidCell(
          child: AccountChainStatsWidget(
            accountChainStatsBloc: _accountChainStatsBloc,
          ),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 2,
            lg: kStaggeredNumOfColumns ~/ 2,
            md: kStaggeredNumOfColumns ~/ 2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: NodeManagement(
            onNodeChangedCallback: widget.onNodeChangedCallback,
          ),
          height: kStaggeredNumOfColumns / 4,
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 6,
            lg: kStaggeredNumOfColumns ~/ 6,
            md: kStaggeredNumOfColumns ~/ 6,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: SecurityWidget(
            widget._onChangeAutoLockTime,
            onStepperNotificationSeeMorePressed:
                widget.onStepperNotificationSeeMorePressed,
          ),
          height: kStaggeredNumOfColumns / 2,
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 6,
            lg: kStaggeredNumOfColumns ~/ 6,
            md: kStaggeredNumOfColumns ~/ 6,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const DisplayWidget(),
          height: kStaggeredNumOfColumns / 2,
        ),
        FluidCell(
          child: const WalletOptions(),
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 6,
            lg: kStaggeredNumOfColumns ~/ 6,
            md: kStaggeredNumOfColumns ~/ 6,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          height: kStaggeredNumOfColumns / 4,
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 2,
            lg: kStaggeredNumOfColumns ~/ 2,
            md: kStaggeredNumOfColumns ~/ 2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const PeersWidget(),
        ),
        FluidCell(
          child: const BackupWidget(),
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 6,
            lg: kStaggeredNumOfColumns ~/ 6,
            md: kStaggeredNumOfColumns ~/ 6,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          height: kStaggeredNumOfColumns / 4,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _accountChainStatsBloc.dispose();
    super.dispose();
  }
}
