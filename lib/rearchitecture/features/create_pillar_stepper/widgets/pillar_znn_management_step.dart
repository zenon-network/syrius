import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// ZNN management step for the pillar creation flow.
class PillarZnnManagementStep extends StatelessWidget {
  /// Creates a [PillarZnnManagementStep].
  const PillarZnnManagementStep({
    required this.accountInfo,
    required this.addressController,
    required this.onNextPressed,
    required this.znnAmountController,
    super.key,
  });

  /// Account balances for the selected address.
  final AccountInfo accountInfo;

  /// Selected address controller displayed by the disabled address field.
  final TextEditingController addressController;

  /// Called when the user can continue to the next step.
  final VoidCallback onNextPressed;

  /// Controller containing the required ZNN amount.
  final TextEditingController znnAmountController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DisabledAddressField(addressController),
        AvailableBalance.stepper(kZnnCoin, accountInfo),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                enabled: false,
                controller: znnAmountController,
                style: const TextStyle(color: AppColors.znnColor),
              ),
            ),
          ],
        ),
        kVerticalGap25,
        DottedBorderInfoWidget(
          text: context.l10n.disassemblePillarToUnlockCoin(kZnnCoin.symbol),
        ),
        kVerticalGap25,
        OutlinedButton(
          onPressed: accountInfo.znn()! >= pillarRegisterZnnAmount
              ? onNextPressed
              : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }
}
