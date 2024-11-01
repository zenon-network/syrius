import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class AmountInfoColumn extends Column {

  AmountInfoColumn({
    required this.context, required this.amount, required this.tokenSymbol, super.key,
  }) : super(
          children: <Widget>[
            Text(
              tokenSymbol,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.subtitleColor,
              ),
            ),
          ],
        );
  final String amount;
  final String tokenSymbol;
  final BuildContext context;
}
