import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Plasma check step for the sentinel creation flow.
class SentinelPlasmaCheckStep extends StatelessWidget {
  /// Creates a [SentinelPlasmaCheckStep].
  const SentinelPlasmaCheckStep({
    required this.addressController,
    required this.onNextPressed,
    super.key,
  });

  /// Selected address controller displayed by the disabled address field.
  final TextEditingController addressController;

  /// Called when the user can continue to the next step.
  final VoidCallback onNextPressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, AsyncSnapshot<PlasmaInfo?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          return _Body(
            addressController: addressController,
            onNextPressed: onNextPressed,
            plasmaInfo: snapshot.data!,
          );
        }
        return const Padding(
          padding: EdgeInsets.all(8),
          child: SyriusLoadingWidget(),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.addressController,
    required this.onNextPressed,
    required this.plasmaInfo,
  });

  final TextEditingController addressController;
  final VoidCallback onNextPressed;
  final PlasmaInfo plasmaInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.morePlasmaRequired,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        kVerticalGap25,
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(addressController),
            ),
            kHorizontalGap25,
            PlasmaIcon(plasmaInfo),
          ],
        ),
        kVerticalGap25,
        OutlinedButton(
          onPressed: plasmaInfo.currentPlasma >= kSentinelPlasmaAmountNeeded
              ? onNextPressed
              : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }
}
