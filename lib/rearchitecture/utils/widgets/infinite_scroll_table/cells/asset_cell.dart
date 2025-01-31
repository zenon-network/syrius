import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/infinite_scroll_table/infinite_scroll_table.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AssetCell extends StatelessWidget {
  const AssetCell({required this.block, super.key});

  final AccountBlock block;

  @override
  Widget build(BuildContext context) {
    final String content = block.token!.symbol;

    final Color textColor = ColorUtils.getTokenColor(block.tokenStandard);

    final String tooltipMessage = block.token!.tokenStandard.toString();

    return InfiniteScrollTableCell.withText(
      content: content,
      tooltipMessage: tooltipMessage,
      textStyle: TextStyle(
        color: textColor,
      ),
    );
  }
}
