import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that collects token decimal and supply metrics.
class TokenMetricsStep extends StatelessWidget {
  /// Creates a [TokenMetricsStep].
  const TokenMetricsStep({
    required this.isContinueEnabled,
    required this.isMintable,
    required this.maxSupplyController,
    required this.maxSupplyKey,
    required this.onBackPressed,
    required this.onChanged,
    required this.onContinuePressed,
    required this.onDecimalsChanged,
    required this.selectedNumDecimals,
    required this.totalSupplyController,
    required this.totalSupplyKey,
    super.key,
  });

  /// Whether the continue button is enabled.
  final bool isContinueEnabled;

  /// Whether max supply should be collected.
  final bool isMintable;

  /// Controller for max supply input.
  final TextEditingController maxSupplyController;

  /// Form key for max supply input.
  final GlobalKey<FormState> maxSupplyKey;

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when a supply field changes.
  final ValueChanged<String> onChanged;

  /// Called when the user can continue.
  final VoidCallback onContinuePressed;

  /// Called when the decimals slider changes.
  final ValueChanged<int> onDecimalsChanged;

  /// Selected decimal count.
  final int selectedNumDecimals;

  /// Controller for total supply input.
  final TextEditingController totalSupplyController;

  /// Form key for total supply input.
  final GlobalKey<FormState> totalSupplyKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: CustomSlider(
            activeColor: AppColors.ztsColor,
            description: context.l10n.numberOfDecimals(selectedNumDecimals),
            startValue: 0,
            min: 0,
            maxValue: 18,
            callback: (double value) {
              onDecimalsChanged(value.toInt());
            },
          ),
        ),
        Visibility(
          visible: isMintable,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: maxSupplyKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: InputField(
                      inputFormatters: FormatUtils.getAmountTextInputFormatters(
                        maxSupplyController.text,
                      ),
                      onChanged: onChanged,
                      controller: maxSupplyController,
                      hintText: context.l10n.maxSupply,
                      validator: isMintable
                          ? (String? value) => InputValidators.correctValue(
                              value,
                              kBigP255m1,
                              selectedNumDecimals,
                              kMinTokenTotalMaxSupply,
                              canBeEqualToMin: true,
                            )
                          : InputValidators.isMaxSupplyZero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: totalSupplyKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    totalSupplyController.text,
                  ),
                  onChanged: onChanged,
                  controller: totalSupplyController,
                  hintText: context.l10n.totalSupply,
                  validator: (String? value) => InputValidators.correctValue(
                    value,
                    isMintable
                        ? maxSupplyController.text.isNotEmpty
                              ? maxSupplyController.text.extractDecimals(
                                  selectedNumDecimals,
                                )
                              : kBigP255m1
                        : kBigP255m1,
                    selectedNumDecimals,
                    isMintable ? BigInt.zero : kMinTokenTotalMaxSupply,
                    canBeEqualToMin: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Row(
              children: <Widget>[
                StepperButton(
                  text: context.l10n.goBack,
                  onPressed: onBackPressed,
                ),
                kHorizontalGap25,
                StepperButton(
                  text: context.l10n.continueText,
                  onPressed: isContinueEnabled ? onContinuePressed : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
