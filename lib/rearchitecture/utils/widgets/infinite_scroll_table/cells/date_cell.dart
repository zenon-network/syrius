import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

class DateCell extends StatelessWidget {
  const DateCell({required this.timestampMs, super.key});

  final int timestampMs;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableCell.withText(
      content: timestampMs == 0
          ? context.l10n.pending
          : FormatUtils.formatDateForTable(timestampMs),
      tooltipMessage: timestampMs == 0
          ? ''
          : FormatUtils.formatDate(
              timestampMs,
              dateFormat: 'MMM d, y HH:mm:ss',
            ),
    );
  }
}
