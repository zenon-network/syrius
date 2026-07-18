import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Step that collects token mint and burn options.
class TokenMintableBurnableStep extends StatelessWidget {
  /// Creates a [TokenMintableBurnableStep].
  const TokenMintableBurnableStep({
    required this.isBurnable,
    required this.isMintable,
    required this.onBackPressed,
    required this.onBurnableChanged,
    required this.onContinuePressed,
    required this.onMintableChanged,
    super.key,
  });

  /// Whether only the owner can burn the token.
  final bool isBurnable;

  /// Whether the token can be minted after creation.
  final bool isMintable;

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when burnable changes.
  final ValueChanged<bool> onBurnableChanged;

  /// Called when the user continues.
  final VoidCallback onContinuePressed;

  /// Called when mintable changes.
  final ValueChanged<bool> onMintableChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Checkbox.adaptive(
              activeColor: AppColors.ztsColor,
              value: isMintable,
              onChanged: (bool? value) {
                if (value != null) {
                  onMintableChanged(value);
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
              activeColor: AppColors.ztsColor,
              value: isBurnable,
              onChanged: (bool? value) {
                if (value != null) {
                  onBurnableChanged(value);
                }
              },
            ),
            kHorizontalGap8,
            Text(
              context.l10n.burn,
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
              onPressed: onBackPressed,
              child: Text(context.l10n.goBack),
            ),
            kHorizontalGap25,
            OutlinedButton(
              onPressed: onContinuePressed,
              child: Text(context.l10n.continueText),
            ),
          ],
        ),
      ],
    );
  }
}
