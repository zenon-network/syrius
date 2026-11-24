import 'package:big_decimal/big_decimal.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the exchange rate between two token amounts.
class ExchangeRate extends StatefulWidget {
  /// Creates an exchange-rate display for the supplied amounts and tokens.
  const ExchangeRate({
    required this._fromAmount,
    required this._toAmount,
    required this._toToken,
    required this._fromToken,
    super.key,
  });
  final BigInt _fromAmount;
  final BigInt _toAmount;
  final Token _toToken;
  final Token _fromToken;

  @override
  State<ExchangeRate> createState() => _ExchangeRateState();
}

class _ExchangeRateState extends State<ExchangeRate> {
  bool _isToggled = false;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible:
          widget._fromAmount > BigInt.zero && widget._toAmount > BigInt.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            context.l10n.exchangeRate,
          ),
          Row(
            children: <Widget>[
              Text(
                _getFormattedRate(),
              ),
              kHorizontalGap4,
              IconButton(
                icon: const Icon(
                  Icons.swap_horiz,
                ),
                onPressed: () => setState(() {
                  _isToggled = !_isToggled;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedRate() {
    final int fromDecimals = widget._fromToken.decimals;
    final int toDecimals = widget._toToken.decimals;
    final String fromSymbol = widget._fromToken.symbol;
    final String toSymbol = widget._toToken.symbol;

    if (widget._fromAmount <= BigInt.zero || widget._toAmount <= BigInt.zero) {
      return '-';
    }
    final BigDecimal fromAmountWithDecimals = BigDecimal.parse(
      AmountUtils.addDecimals(widget._fromAmount, fromDecimals),
    );
    final BigDecimal toAmountWithDecimals = BigDecimal.parse(
      AmountUtils.addDecimals(widget._toAmount, toDecimals),
    );
    if (_isToggled) {
      final BigDecimal rate = fromAmountWithDecimals.divide(
        toAmountWithDecimals,
        scale: 5,
        roundingMode: RoundingMode.DOWN,
      );
      return '1 $toSymbol = ${rate.toDouble().toStringFixedNumDecimals(5)} '
          '$fromSymbol';
    } else {
      final BigDecimal rate = toAmountWithDecimals.divide(
        fromAmountWithDecimals,
        scale: 5,
        roundingMode: RoundingMode.DOWN,
      );
      return '1 $fromSymbol = ${rate.toDouble().toStringFixedNumDecimals(5)} '
          '$toSymbol';
    }
  }
}
