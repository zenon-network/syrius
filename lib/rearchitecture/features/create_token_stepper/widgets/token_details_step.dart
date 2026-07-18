import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that collects token name, symbol, and domain.
class TokenDetailsStep extends StatelessWidget {
  /// Creates a [TokenDetailsStep].
  const TokenDetailsStep({
    required this.isContinueEnabled,
    required this.onBackPressed,
    required this.onChanged,
    required this.onContinuePressed,
    required this.tokenDomainController,
    required this.tokenDomainKey,
    required this.tokenNameController,
    required this.tokenNameKey,
    required this.tokenSymbolController,
    required this.tokenSymbolKey,
    super.key,
  });

  /// Whether the continue button is enabled.
  final bool isContinueEnabled;

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when any field changes.
  final ValueChanged<String> onChanged;

  /// Called when the user can continue.
  final VoidCallback onContinuePressed;

  /// Controller for token domain input.
  final TextEditingController tokenDomainController;

  /// Form key for token domain input.
  final GlobalKey<FormState> tokenDomainKey;

  /// Controller for token name input.
  final TextEditingController tokenNameController;

  /// Form key for token name input.
  final GlobalKey<FormState> tokenNameKey;

  /// Controller for token symbol input.
  final TextEditingController tokenSymbolController;

  /// Form key for token symbol input.
  final GlobalKey<FormState> tokenSymbolKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: tokenNameKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  onChanged: onChanged,
                  controller: tokenNameController,
                  hintText: context.l10n.tokenName,
                  validator: Validations.tokenName,
                ),
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: tokenSymbolKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  onChanged: onChanged,
                  controller: tokenSymbolController,
                  validator: Validations.tokenSymbol,
                  hintText: context.l10n.tokenSymbol,
                ),
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        Form(
          key: tokenDomainKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            suffixIcon: FieldSuffixButtons(
              controller: tokenDomainController,
            ),
            onChanged: onChanged,
            controller: tokenDomainController,
            validator: InputValidators.checkUrl,
            hintText: context.l10n.tokenDomain,
          ),
        ),
        kVerticalGap25,
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
    );
  }
}
