import 'package:big_decimal/big_decimal.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';

class ExchangeRateWidget extends StatefulWidget {
  final BigInt fromAmount;
  final int fromDecimals;
  final String fromSymbol;
  final BigInt toAmount;
  final int toDecimals;
  final String toSymbol;

  const ExchangeRateWidget({
    required this.fromAmount,
    required this.fromDecimals,
    required this.fromSymbol,
    required this.toAmount,
    required this.toDecimals,
    required this.toSymbol,
    Key? key,
  }) : super(key: key);

  @override
  State<ExchangeRateWidget> createState() => _ExchangeRateWidgetState();
}

class _ExchangeRateWidgetState extends State<ExchangeRateWidget> {
  bool _isToggled = false;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.fromAmount > BigInt.zero && widget.toAmount > BigInt.zero,
      child: Row(
        children: [
          Text(
            _getFormattedRate(),
            style:
                const TextStyle(fontSize: 14.0, color: AppColors.subtitleColor),
          ),
          const SizedBox(
            width: 5.0,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() {
                _isToggled = !_isToggled;
              }),
              child: const Icon(
                Icons.swap_horiz,
                color: AppColors.subtitleColor,
                size: 22.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedRate() {
    if (widget.fromAmount <= BigInt.zero || widget.toAmount <= BigInt.zero) {
      return '-';
    }
    final fromAmountWithDecimals = BigDecimal.createAndStripZerosForScale(
        widget.fromAmount, widget.fromDecimals, widget.fromDecimals);
    final toAmountWithDecimals = BigDecimal.createAndStripZerosForScale(
        widget.toAmount, widget.toDecimals, widget.toDecimals);
    if (_isToggled) {
      final rate = (fromAmountWithDecimals.divide(toAmountWithDecimals,
          roundingMode: RoundingMode.DOWN));
      return '1 ${widget.toSymbol} = ${rate.toDouble().toStringFixedNumDecimals(5)} ${widget.fromSymbol}';
    } else {
      final rate = (toAmountWithDecimals.divide(fromAmountWithDecimals,
          roundingMode: RoundingMode.DOWN));
      return '1 ${widget.fromSymbol} = ${rate.toDouble().toStringFixedNumDecimals(5)} ${widget.toSymbol}';
    }
  }
}
