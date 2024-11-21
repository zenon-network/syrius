import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/models/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class TransferTabChild extends StatefulWidget {
  TransferTabChild({
    super.key,
  });

  @override
  State<TransferTabChild> createState() => _TransferTabChildState();
}

class _TransferTabChildState extends State<TransferTabChild> {
  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      children: <FluidCell>[
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 2,
            lg: kStaggeredNumOfColumns ~/ 2,
            md: kStaggeredNumOfColumns ~/ 2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const SendCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 2,
            lg: kStaggeredNumOfColumns ~/ 2,
            md: kStaggeredNumOfColumns ~/ 2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const ReceiveCard(),
        ),
        FluidCell(
          child: LatestTransactionsCard(
            type: CardType.latestTransactions,
          ),
          width: kStaggeredNumOfColumns ~/ 2,
          height: kStaggeredNumOfColumns / 3,
        ),
        const FluidCell(
          child: PendingTransactions(),
          width: kStaggeredNumOfColumns ~/ 2,
          height: kStaggeredNumOfColumns / 3,
        ),
      ],
    );
  }
}
