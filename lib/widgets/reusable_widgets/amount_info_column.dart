import 'package:flutter/material.dart';

class AmountInfoColumn extends Column {

  AmountInfoColumn({
    required this.context, required this.amount, required this.tokenSymbol, super.key,
  }) : super(
          children: [
            Text(
              tokenSymbol,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        );
  final String amount;
  final String tokenSymbol;
  final BuildContext context;
}
