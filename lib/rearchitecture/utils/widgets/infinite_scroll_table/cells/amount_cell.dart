import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/infinite_scroll_table/infinite_scroll_table.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/formatted_amount_with_tooltip.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AmountCell extends StatelessWidget {
  const AmountCell({required this.block, super.key});

  final AccountBlock block;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableCell(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: FormattedAmountWithTooltip(
          amount: block.amount.addDecimals(
            block.token?.decimals ?? 0,
          ),
          tokenSymbol: block.token?.symbol ?? '',
          builder: (String formattedAmount, String tokenSymbol) => Text(
            formattedAmount,
          ),
        ),
      ),
    );
  }
}
