import 'dart:async';

import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class P2pSwapTabChild extends StatefulWidget {
  const P2pSwapTabChild({super.key});

  @override
  State createState() => _P2pSwapTabChildState();
}

class _P2pSwapTabChildState extends State<P2pSwapTabChild> {
  bool _hasCheckedLocalTime = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasCheckedLocalTime) {
      return;
    }

    _hasCheckedLocalTime = true;
    unawaited(
      NodeUtils.checkForLocalTimeDiscrepancy(
        context.l10n.localTimeDiscrepancyDetected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildLayout(context);
  }

  StandardFluidLayout _buildLayout(BuildContext context) {
    return StandardFluidLayout(
      children: <FluidCell>[
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
            builder: (_, _, _) => const P2pSwapsCard(),
          ),
        ),
      ],
    );
  }
}
