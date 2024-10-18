import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AcceleratorTabChild extends StatelessWidget {

  const AcceleratorTabChild({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PillarInfo>>(
      future:
          zenon!.embedded.pillar.getByOwner(Address.parse(kSelectedAddress!)),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error.toString());
        } else if (snapshot.hasData) {
          return _getLayout(
              context, snapshot.data!.isNotEmpty ? snapshot.data!.first : null,);
        }
        return const SyriusLoadingWidget();
      },
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
