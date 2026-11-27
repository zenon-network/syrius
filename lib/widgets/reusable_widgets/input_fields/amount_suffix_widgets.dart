import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Trailing input suffix showing a token symbol badge and optional max button.
class AmountSuffixWidgets extends StatelessWidget {
  /// Creates an [AmountSuffixWidgets].
  const AmountSuffixWidgets(
    this.tokenId, {
    this.onMaxPressed,
    super.key,
  });

  /// Token whose symbol and color are displayed in the badge.
  final Token tokenId;

  /// Optional callback enabling and handling the "MAX" button tap.
  final VoidCallback? onMaxPressed;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onMax = onMaxPressed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AmountSuffixTokenSymbolWidget(
          token: tokenId,
          context: context,
        ),
        if (onMax != null)
          AmountSuffixMaxWidget(
            onPressed: onMax,
            context: context,
          ),
      ],
    );
  }
}

/// Colored pill container displaying a token's symbol inside an amount input.
class AmountSuffixTokenSymbolWidget extends Container {
  /// Creates an [AmountSuffixTokenSymbolWidget].
  AmountSuffixTokenSymbolWidget({
    required Token token,
    required BuildContext context,
    super.key,
  }) : super(
          height: kAmountSuffixHeight,
          width: kAmountSuffixWidth,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(
            right: kContentPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kAmountSuffixRadius),
            color: ColorUtils.getTokenColor(token.tokenStandard),
          ),
          child: Text(
            token.symbol,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Colors.white,
                ),
          ),
        );
}

/// Outlined "MAX" suffix button for filling the maximum available token amount.
class AmountSuffixMaxWidget extends InkWell {
  /// Creates an [AmountSuffixMaxWidget].
  AmountSuffixMaxWidget({
    required VoidCallback onPressed,
    required BuildContext context,
    super.key,
  }) : super(
          onTap: onPressed,
          child: Container(
            height: kAmountSuffixHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kAmountSuffixRadius),
              border: Border.all(
                color: AppColors.maxAmountBorder,
              ),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8,
            ),
            child: Text(
              context.l10n.max.toUpperCase(),
            ),
          ),
        );
}
