import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/accelerator_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AcceleratorTabChild extends StatelessWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const AcceleratorTabChild({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PillarInfo?>(
      future: _getPillarForSelectedAddress(),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error.toString());
        } else if (snapshot.hasData) {
          return _getLayout(context, snapshot.data);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  /// Resolves the selected account's pillar by owner address first,
  /// then by block-producing address, so producer-key accounts can
  /// vote on Accelerator projects too (VoteByProdAddress).
  Future<PillarInfo?> _getPillarForSelectedAddress() async {
    final address = Address.parse(kSelectedAddress!);
    final byOwner = await zenon!.embedded.pillar.getByOwner(address);
    if (byOwner.isNotEmpty) {
      return byOwner.first;
    }
    final all = await zenon!.embedded.pillar.getAll();
    return AcceleratorUtils.pillarForAddress(all.list, address);
  }

  StandardFluidLayout _getLayout(BuildContext context, PillarInfo? pillarInfo) {
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
          child: AcceleratorDonations(
            onStepperNotificationSeeMorePressed:
                onStepperNotificationSeeMorePressed,
          ),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const AcceleratorStats(),
        ),
        FluidCell(
          width: context.layout.value(
            lg: kStaggeredNumOfColumns ~/ 3,
            xl: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: CreateProject(
            onStepperNotificationSeeMorePressed:
                onStepperNotificationSeeMorePressed,
          ),
        ),
        FluidCell(
          width: kStaggeredNumOfColumns,
          child: Consumer<SelectedAddressNotifier>(
            builder: (_, __, ___) => AccProjectList(
              onStepperNotificationSeeMorePressed:
                  onStepperNotificationSeeMorePressed,
              pillarInfo: pillarInfo,
            ),
          ),
          height: kStaggeredNumOfColumns / 2,
        ),
      ],
    );
  }
}
