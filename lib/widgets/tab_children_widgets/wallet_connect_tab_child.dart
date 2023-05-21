import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/wallet_connect_widgets/wallet_connect_pairings_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/wallet_connect_widgets/wallet_connect_uri_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/wallet_connect_widgets/wallet_connection_sessions_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletConnectTabChild extends StatelessWidget {
  const WalletConnectTabChild({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 4,
            lg: kStaggeredNumOfColumns ~/ 4,
            md: kStaggeredNumOfColumns ~/ 4,
            sm: kStaggeredNumOfColumns ~/ 4,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const WalletConnectUriCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xs: kStaggeredNumOfColumns,
          ),
          height: kStaggeredNumOfColumns / 3,
          child: const WalletConnectPairingsCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xs: kStaggeredNumOfColumns,
          ),
          height: kStaggeredNumOfColumns / 3,
          child: const WalletConnectSessionsCard(),
        ),
      ],
    );
  }
}
