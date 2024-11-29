import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DateCell extends StatelessWidget {
  const DateCell({required this.block, super.key});

  final AccountBlock block;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableCell.withText(
      content: block.confirmationDetail?.momentumTimestamp == null
          ? context.l10n.pending
          : FormatUtils.formatData(
        block.confirmationDetail!.momentumTimestamp * 1000,
      ),
    );
  }
}
