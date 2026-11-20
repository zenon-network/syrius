import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/utils/accelerator_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Body for the Accelerator tab's pillar-lookup [snapshot].
///
/// Branches on the connection state, not [AsyncSnapshot.hasData]: the
/// future completes with `null` for an address that has no pillar role,
/// and `hasData` would keep the tab on the loading widget forever.
@visibleForTesting
Widget acceleratorTabBody(
  AsyncSnapshot<PillarInfo?> snapshot,
  Widget Function(PillarInfo? pillarInfo) layoutBuilder,
) {
  if (snapshot.hasError) {
    return SyriusErrorWidget(snapshot.error.toString());
  }
  if (snapshot.connectionState == ConnectionState.done) {
    return layoutBuilder(snapshot.data);
  }
  return const SyriusLoadingWidget();
}

class AcceleratorTabChild extends StatelessWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const AcceleratorTabChild({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PillarInfo?>(
      future: AcceleratorUtils.selectedAddressPillar(),
      builder: (_, snapshot) => acceleratorTabBody(
        snapshot,
        (pillarInfo) => _getLayout(context, pillarInfo),
      ),
    );
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
