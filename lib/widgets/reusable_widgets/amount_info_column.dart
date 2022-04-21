import 'package:flutter/material.dart';

class AmountInfoColumn extends Column {
  final String amount;
  final String tokenSymbol;
  final BuildContext context;

  AmountInfoColumn({
    Key? key,
    required this.context,
    required this.amount,
    required this.tokenSymbol,
  }) : super(
          key: key,
          children: [
            Text(
              tokenSymbol,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.subtitle2,
            ),
          ],
        );
}
