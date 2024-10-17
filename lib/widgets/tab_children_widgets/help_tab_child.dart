import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class HelpTabChild extends StatelessWidget {
  const HelpTabChild({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 2,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const AboutCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 2,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const UpdateCard(),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 2,
            xs: kStaggeredNumOfColumns ~/ 2,
          ),
          child: const CommunityCard(),
        ),
      ],
    );
  }
}
