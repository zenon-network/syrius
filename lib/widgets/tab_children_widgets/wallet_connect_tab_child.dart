import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletConnectTabChild extends StatelessWidget {
  const WalletConnectTabChild({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 3,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const WalletConnectQrCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 3,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const WalletConnectUriCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 3,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const WalletConnectCameraCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xs: kStaggeredNumOfColumns,
          ),
          height: kStaggeredNumOfColumns / 4,
          child: const WalletConnectPairingsCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xs: kStaggeredNumOfColumns,
          ),
          height: kStaggeredNumOfColumns / 4,
          child: const WalletConnectSessionsCard(),
        ),
      ],
    );
  }
}
