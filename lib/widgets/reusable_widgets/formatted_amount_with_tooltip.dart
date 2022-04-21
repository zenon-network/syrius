import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormattedAmountWithTooltip extends Tooltip {
  final num amount;
  final String tokenSymbol;
  final Widget Function(String, String) builder;

  FormattedAmountWithTooltip({
    Key? key,
    required this.amount,
    required this.tokenSymbol,
    required this.builder,
  }) : super(
          key: key,
          message: '$amount $tokenSymbol',
          child: builder(NumberFormat.compact().format(amount), tokenSymbol),
        );
}
