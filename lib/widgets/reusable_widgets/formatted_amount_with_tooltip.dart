import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Tooltip displaying a compact token amount with the full value on hover.
class FormattedAmountWithTooltip extends Tooltip {
  /// Creates a [FormattedAmountWithTooltip].
  FormattedAmountWithTooltip({
    required this.amount,
    required this.tokenSymbol,
    required this.builder,
    super.key,
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
            tokenSymbol,
          ),
        );

  /// Full formatted token amount string shown in the tooltip.
  final String amount;

  /// Symbol of the token represented by [amount].
  final String tokenSymbol;

  /// Builder receiving the compact amount string and [tokenSymbol].
  final Widget Function(String, String) builder;
}
