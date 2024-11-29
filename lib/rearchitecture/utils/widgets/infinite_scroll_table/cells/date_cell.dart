import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DateCell extends StatelessWidget {
  const DateCell({required this.block, super.key});

  final AccountBlock block;

  @override
  Widget build(BuildContext context) {
    final int millis = (block.confirmationDetail?.momentumTimestamp ?? 0) * 1000;

    return InfiniteScrollTableCell.withText(
      content: millis == 0
          ? context.l10n.pending
          : FormatUtils.formatDateForTable(
        millis,
      ),
      tooltipMessage: millis == 0
          ? ''
          : FormatUtils.formatDate(
        millis,
        dateFormat: 'MMM d, y HH:mm:ss'
      ),
    );
  }
}
