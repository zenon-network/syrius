import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AmountSuffixWidgets extends StatelessWidget {

  const AmountSuffixWidgets(
    this.tokenId, {
    this.onMaxPressed,
    super.key,
  });
  final Token tokenId;
  final VoidCallback? onMaxPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AmountSuffixTokenSymbolWidget(
          token: tokenId,
          context: context,
        ),
        Visibility(
          visible: onMaxPressed != null,
          child: AmountSuffixMaxWidget(
            onPressed: onMaxPressed!,
            context: context,
          ),
        ),
      ],
    );
  }
}

class AmountSuffixTokenSymbolWidget extends Container {
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

class AmountSuffixMaxWidget extends InkWell {
  AmountSuffixMaxWidget({
    required VoidCallback onPressed,
    required BuildContext context,
    super.key,
  }) : super(
          onTap: onPressed,
          child: Container(
            height: kAmountSuffixHeight,
            width: kAmountSuffixWidth,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(
              right: kContentPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kAmountSuffixRadius),
              border: Border.all(
                color: AppColors.maxAmountBorder,
              ),
            ),
            child: Text(
              'MAX',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
}
