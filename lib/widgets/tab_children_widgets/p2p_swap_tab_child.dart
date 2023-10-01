import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swaps_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swap_options_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class P2pSwapTabChild extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const P2pSwapTabChild({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State createState() => P2pSwapTabChildState();
}

class P2pSwapTabChildState extends State<P2pSwapTabChild> {
  @override
  void initState() {
    super.initState();
    NodeUtils.checkForLocalTimeDiscrepancy(
        '''Local time discrepancy detected. Please confirm your operating '''
        '''system's time is correct before conducting P2P swaps.''');
  }

  @override
  Widget build(BuildContext context) {
    return _getLayout(context);
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
                  widget.onStepperNotificationSeeMorePressed,
            ),
          ),
        ),
      ],
    );
  }
}
