import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that displays the token issuance address and required ZNN fee.
class TokenCreationStep extends StatelessWidget {
  /// Creates a [TokenCreationStep].
  const TokenCreationStep({
    required this.accountInfo,
    required this.addressController,
    required this.onContinuePressed,
    required this.tokenData,
    super.key,
  });

  /// Account info for the selected address.
  final AccountInfo accountInfo;

  /// Selected address controller displayed by the disabled address field.
  final TextEditingController addressController;

  /// Called when the user can continue to token details.
  final VoidCallback onContinuePressed;

  /// Token data draft updated by this step.
  final ValueNotifier<NewTokenData> tokenData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.tokenIssuanceAddressDescription,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        kVerticalGap16,
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(addressController),
            ),
          ],
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        DottedBorderInfoWidget(
          text: context.l10n.burnTokenIssueFee(
            tokenZtsIssueFeeInZnn.addDecimals(coinDecimals),
            kZnnCoin.symbol,
          ),
          borderColor: AppColors.ztsColor,
        ),
        kVerticalGap16,
        OutlinedButton(
          onPressed:
              accountInfo.getBalance(kZnnCoin.tokenStandard) >=
                  tokenZtsIssueFeeInZnn
              ? () {
                  tokenData.value = tokenData.value.copyWith(
                    address: addressController.text,
                  );
                  onContinuePressed();
                }
              : null,
          child: Text(context.l10n.continueText),
        ),
      ],
    );
  }
}
