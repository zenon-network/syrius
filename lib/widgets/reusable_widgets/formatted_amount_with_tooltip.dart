import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

class FormattedAmountWithTooltip extends Tooltip {

  FormattedAmountWithTooltip({
    required this.amount, required this.tokenSymbol, required this.builder, super.key,
  }) : super(
          message: '$amount $tokenSymbol',
          child: builder(
              amount.toNum() == 0
                  ? '0'
                  : amount.startsWith('0.')
                      ? amount
                      : NumberFormat.compact().format(amount.toNum()).length > 8
                          ? '…'
                          : NumberFormat.compact().format(amount.toNum()),
              tokenSymbol,),
        );
  final String amount;
  final String tokenSymbol;
  final Widget Function(String, String) builder;
}
