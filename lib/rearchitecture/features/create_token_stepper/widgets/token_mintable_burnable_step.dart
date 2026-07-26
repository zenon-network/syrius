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
  late final ValueNotifier<bool> _isBurnable;
  late final ValueNotifier<bool> _isMintable;

  @override
  void initState() {
    super.initState();
    _isBurnable = .new(widget.tokenData.value.isBurnable);
    _isMintable = .new(widget.tokenData.value.isMintable);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: _isMintable,
              builder: (_, bool value, _) {
                return Checkbox.adaptive(
                  key: const Key('token_mintable_checkbox'),
                  activeColor: AppColors.ztsColor,
                  value: value,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isMintable.value = value;
                      });
                    }
                  },
                );
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
            ValueListenableBuilder<bool>(
              valueListenable: _isBurnable,
              builder: (_, bool value, _) {
                return Checkbox.adaptive(
                  key: const Key('token_burnable_checkbox'),
                  activeColor: AppColors.ztsColor,
                  value: value,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _isBurnable.value = value;
                      });
                    }
                  },
                );
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
                widget.tokenData.value = widget.tokenData.value.copyWith(
                  isMintable: _isMintable.value,
                  isBurnable: _isBurnable.value,
                );
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
