import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_token_stepper/utils/token_validation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that collects token name, symbol, and domain.
class TokenDetailsStep extends StatefulWidget {
  /// Creates a [TokenDetailsStep].
  const TokenDetailsStep({
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.tokenData,
    required this.tokenDomainController,
    required this.tokenNameController,
    required this.tokenSymbolController,
    super.key,
  });

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when the user can continue.
  final VoidCallback onContinuePressed;

  /// Token data draft updated by this step.
  final ValueNotifier<NewTokenData> tokenData;

  /// Controller for token domain input.
  final TextEditingController tokenDomainController;

  /// Controller for token name input.
  final TextEditingController tokenNameController;

  /// Controller for token symbol input.
  final TextEditingController tokenSymbolController;

  @override
  State<TokenDetailsStep> createState() => _TokenDetailsStepState();
}

class _TokenDetailsStepState extends State<TokenDetailsStep> {
  String? _validateTokenName(BuildContext context, String value) {
    return switch (validateTokenNameError(value)) {
      null => null,
      TokenNameValidationError.empty => context.l10n.tokenNameCannotBeEmpty,
      TokenNameValidationError.tooLong => context.l10n.tokenNameMaxLength(
        tokenNameMaxLength,
      ),
      TokenNameValidationError.invalidCharacters =>
        context.l10n.tokenNameAllowedCharacters,
    };
  }

  String? _validateTokenSymbol(BuildContext context, String value) {
    return switch (validateTokenSymbolError(value)) {
      null => null,
      TokenSymbolValidationError.empty => context.l10n.tokenSymbolCannotBeEmpty,
      TokenSymbolValidationError.tooLong => context.l10n.tokenSymbolMaxLength(
        tokenSymbolMaxLength,
      ),
      TokenSymbolValidationError.invalidCharacters =>
        context.l10n.tokenSymbolUppercaseAlphanumericOnly,
      TokenSymbolValidationError.reserved => context.l10n.tokenSymbolCannotBe(
        tokenSymbolExceptions.join(', '),
      ),
    };
  }

  String? _validateTokenDomain(BuildContext context, String value) {
    return switch (validateTokenDomainError(value)) {
      null => null,
      TokenDomainValidationError.empty => context.l10n.tokenDomainCannotBeEmpty,
      TokenDomainValidationError.tooLong => context.l10n.tokenDomainMaxLength(
        kTokenDomainMaxLength,
      ),
      TokenDomainValidationError.invalidFormat =>
        context.l10n.enterValidDomainWithoutProtocol,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.tokenNameController,
        widget.tokenSymbolController,
        widget.tokenDomainController,
      ]),
      builder: (_, _) {
        final String name = widget.tokenNameController.text;
        final String symbol = widget.tokenSymbolController.text;
        final String domain = widget.tokenDomainController.text;

        final String? nameError = _validateTokenName(context, name);
        final String? symbolError = _validateTokenSymbol(context, symbol);
        final String? domainError = _validateTokenDomain(context, domain);
        final bool areTokenDetailsCorrect =
            nameError == null && symbolError == null && domainError == null;

        return Column(
          children: <Widget>[
            TextField(
              key: const Key('token_name_field'),
              controller: widget.tokenNameController,
              decoration: InputDecoration(
                errorText: name.isNotEmpty ? nameError : null,
                hintText: context.l10n.tokenName,
              ),
            ),
            kVerticalGap16,
            TextField(
              key: const Key('token_symbol_field'),
              controller: widget.tokenSymbolController,
              decoration: InputDecoration(
                errorText: symbol.isNotEmpty ? symbolError : null,
                hintText: context.l10n.tokenSymbol,
              ),
            ),
            kVerticalGap16,
            TextField(
              key: const Key('token_domain_field'),
              controller: widget.tokenDomainController,
              decoration: InputDecoration(
                errorText: domain.isNotEmpty ? domainError : null,
                hintText: context.l10n.tokenDomain,
                suffixIcon: FieldSuffixButtons(
                  controller: widget.tokenDomainController,
                ),
              ),
            ),
            kVerticalGap25,
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: widget.onBackPressed,
                  child: Text(context.l10n.goBack),
                ),
                kHorizontalGap25,
                OutlinedButton(
                  key: const Key('token_details_next_button'),
                  onPressed: areTokenDetailsCorrect ? _onContinuePressed : null,
                  child: Text(context.l10n.continueText),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _onContinuePressed() {
    widget.tokenData.value = widget.tokenData.value.copyWith(
      tokenDomain: widget.tokenDomainController.text,
      tokenName: widget.tokenNameController.text,
      tokenSymbol: widget.tokenSymbolController.text,
    );
    widget.onContinuePressed();
  }
}
