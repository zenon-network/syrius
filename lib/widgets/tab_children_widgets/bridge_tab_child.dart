import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/bridge_widgets/dynamic_multiplier_rewards_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/bridge_widgets/join_liquidity_program_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/bridge_widgets/swap_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/standard_fluid_layout.dart';

class BridgeTabChild extends StatelessWidget {
  const BridgeTabChild({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const JoinLiquidityProgramCard(),
        ),
        FluidCell(
          height: kStaggeredNumOfColumns / 2,
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 1.5,
            lg: kStaggeredNumOfColumns ~/ 1.5,
            md: kStaggeredNumOfColumns ~/ 1.5,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const SwapCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 2,
            xs: kStaggeredNumOfColumns,
          ),
          child: const DynamicMultiplierRewardsCard(),
        ),
      ],
    );
  }
}
