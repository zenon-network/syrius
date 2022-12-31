import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SettingsTabChild extends StatefulWidget {
  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback _onResyncWalletPressed;
  final VoidCallback onStepperNotificationSeeMorePressed;
  final VoidCallback onNodeChangedCallback;

  const SettingsTabChild(
    this._onChangeAutoLockTime,
    this._onResyncWalletPressed, {
    required this.onStepperNotificationSeeMorePressed,
    required this.onNodeChangedCallback,
    Key? key,
  }) : super(key: key);

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
        const FluidCell(
          child: GeneralWidget(),
          height: kStaggeredNumOfColumns / 3,
        ),
        FluidCell(
          child: AccountChainStatsWidget(
            accountChainStatsBloc: _accountChainStatsBloc,
          ),
          height: kStaggeredNumOfColumns / 3,
        ),
        FluidCell(
          child: SecurityWidget(
            widget._onChangeAutoLockTime,
            onStepperNotificationSeeMorePressed:
                widget.onStepperNotificationSeeMorePressed,
          ),
          height: kStaggeredNumOfColumns / 3,
        ),
        FluidCell(
          child: WalletOptions(
            widget._onResyncWalletPressed,
          ),
          height: kStaggeredNumOfColumns / 3,
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
          height: kStaggeredNumOfColumns / 6,
        ),
        const FluidCell(
          child: DisplayWidget(),
          height: kStaggeredNumOfColumns / 6,
        ),
        const FluidCell(
          child: BackupWidget(),
          height: kStaggeredNumOfColumns / 6,
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
