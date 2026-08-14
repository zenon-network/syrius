import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Step that collects token mint and burn options.
class TokenMintableBurnableStep extends StatefulWidget {
  /// Creates a [TokenMintableBurnableStep].
  const TokenMintableBurnableStep({
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.tokenData,
    super.key,
  });

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when the user continues.
  final VoidCallback onContinuePressed;

  /// Token data draft updated by this step.
  final ValueNotifier<NewTokenData> tokenData;

  @override
  State<TokenMintableBurnableStep> createState() =>
      _TokenMintableBurnableStepState();
}

class _TokenMintableBurnableStepState extends State<TokenMintableBurnableStep> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Checkbox.adaptive(
              key: const Key('token_mintable_checkbox'),
              activeColor: AppColors.ztsColor,
              value: widget.tokenData.value.isMintable,
              onChanged: (bool? value) {
                if (value != null) {
                  widget.tokenData.value = widget.tokenData.value.copyWith(
                    isMintable: value,
                  );
                }
              },
            ),
            kHorizontalGap8,
            Text(
              context.l10n.mintable,
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            StandardTooltipIcon(
              context.l10n.tokenMintableTooltip,
              Icons.help,
              iconColor: AppColors.ztsColor,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Checkbox.adaptive(
              key: const Key('token_burnable_checkbox'),
              activeColor: AppColors.ztsColor,
              value: widget.tokenData.value.isBurnable,
              onChanged: (bool? value) {
                if (value != null) {
                  widget.tokenData.value = widget.tokenData.value.copyWith(
                    isBurnable: value,
                  );
                }
              },
            ),
            kHorizontalGap8,
            Text(
              context.l10n.burnableToken,
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            const Icon(
              Icons.whatshot,
              color: AppColors.ztsColor,
            ),
            StandardTooltipIcon(
              context.l10n.tokenBurnTooltip,
              Icons.help,
              iconColor: AppColors.ztsColor,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: widget.onBackPressed,
              child: Text(context.l10n.goBack),
            ),
            kHorizontalGap25,
            OutlinedButton(
              key: const Key('token_options_next_button'),
              onPressed: () {
                widget.onContinuePressed();
              },
              child: Text(context.l10n.continueText),
            ),
          ],
        ),
      ],
    );
  }
}
