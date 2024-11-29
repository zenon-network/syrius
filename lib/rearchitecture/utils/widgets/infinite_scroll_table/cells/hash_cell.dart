import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/infinite_scroll_table/infinite_scroll_table.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HashCell extends StatelessWidget {
  const HashCell({required this.hash, super.key});

  final Hash hash;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableCell.withText(
      content: hash.toShortString(),
      flex: 2,
      tooltipMessage: hash.toString(),
      textToBeCopied: hash.toString(),
    );
  }
}
