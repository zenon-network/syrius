import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';

class ExchangeRateWidget extends StatefulWidget {
  final int fromAmount;
  final int fromDecimals;
  final String fromSymbol;
  final int toAmount;
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
      visible: widget.fromAmount > 0 && widget.toAmount > 0,
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
    if (widget.fromAmount <= 0 || widget.toAmount <= 0) {
      return '-';
    }
    num from = widget.fromAmount.addDecimals(widget.fromDecimals);
    num to = widget.toAmount.addDecimals(widget.toDecimals);
    if (_isToggled) {
      final rate = from / to;
      return '1 ${widget.toSymbol} = ${rate.toStringFixedNumDecimals(5)} ${widget.fromSymbol}';
    } else {
      final rate = to / from;
      return '1 ${widget.fromSymbol} = ${rate.toStringFixedNumDecimals(5)} ${widget.toSymbol}';
    }
  }
}
