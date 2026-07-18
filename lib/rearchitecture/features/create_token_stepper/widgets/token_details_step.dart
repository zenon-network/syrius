import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that collects token name, symbol, and domain.
class TokenDetailsStep extends StatefulWidget {
  /// Creates a [TokenDetailsStep].
  const TokenDetailsStep({
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.tokenDomainController,
    required this.tokenNameController,
    required this.tokenSymbolController,
    super.key,
  });

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when the user can continue.
  final VoidCallback onContinuePressed;

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

  // TODO(maznnwell): the error messages from of validators seem to be mixed up
  String? get _nameError =>
      Validations.tokenName(widget.tokenNameController.text);

  String? get _symbolError =>
      Validations.tokenSymbol(widget.tokenSymbolController.text);

  String? get _domainError =>
      InputValidators.checkUrl(widget.tokenDomainController.text);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        widget.tokenNameController,
        widget.tokenSymbolController,
        widget.tokenDomainController,
      ]),
      builder: (_, _) => Column(
        children: <Widget>[
          TextField(
            controller: widget.tokenNameController,
            decoration: InputDecoration(
              errorText: widget.tokenNameController.text.isNotEmpty
                  ? _nameError
                  : null,
              hintText: context.l10n.tokenName,
            ),
          ),
          kVerticalGap16,
          TextField(
            controller: widget.tokenSymbolController,
            decoration: InputDecoration(
              errorText: widget.tokenSymbolController.text.isNotEmpty
                  ? _symbolError
                  : null,
              hintText: context.l10n.tokenSymbol,
            ),
          ),
          kVerticalGap16,
          TextField(
            controller: widget.tokenDomainController,
            decoration: InputDecoration(
              errorText: widget.tokenDomainController.text.isNotEmpty
                  ? _domainError
                  : null,
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
                onPressed: _areTokenDetailsCorrect()
                    ? widget.onContinuePressed
                    : null,
                child: Text(context.l10n.continueText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _areTokenDetailsCorrect() =>
      Validations.tokenName(
            widget.tokenNameController.text,
          ) ==
          null &&
      Validations.tokenSymbol(
            widget.tokenSymbolController.text,
          ) ==
          null &&
      InputValidators.checkUrl(
            widget.tokenDomainController.text,
          ) ==
          null;
}
