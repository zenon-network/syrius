import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class AmountInfoColumn extends Column {
  AmountInfoColumn({
    required BuildContext context,
    required String amount,
    required String tokenSymbol,
    Color? tokenSymbolColor,
    super.key,
  }) : super(
        mainAxisAlignment: .center,
         children: <Widget>[
           Text(
             tokenSymbol,
             style: Theme.of(context).textTheme.titleSmall!.copyWith(
               color: tokenSymbolColor,
             ),
           ),
           Text(
             amount,
             style: Theme.of(context).textTheme.labelSmall?.copyWith(
               color: AppColors.subtitleColor,
             ),
           ),
         ],
       );
}
