import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swaps_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swap_options_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class P2pSwapTabChild extends StatelessWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const P2pSwapTabChild({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Enable P2P Swaps UI on mainnet
    return (kNodeChainId ?? 1) == 1
        ? const SyriusErrorWidget(
            'P2P Swaps can\'t be done on mainnet yet.\nPlease connect to a HyperCore One testnet node, such as: wss://testnet.deeznnutz.com:3598')
        : _getLayout(context);
  }

  StandardFluidLayout _getLayout(BuildContext context) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          height: kStaggeredNumOfColumns / 2,
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const P2pSwapOptionsCard(),
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
          child: Consumer<SelectedAddressNotifier>(
            builder: (_, __, ___) => P2pSwapsCard(
              onStepperNotificationSeeMorePressed:
                  onStepperNotificationSeeMorePressed,
            ),
          ),
        ),
      ],
    );
  }
}
