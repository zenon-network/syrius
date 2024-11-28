import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/infinite_scroll_table/infinite_scroll_table.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AssetCell extends StatelessWidget {
  const AssetCell({required this.block, super.key});
  
  final AccountBlock block;

  @override
  Widget build(BuildContext context) {
    late final Widget child;
    if (block.token == null) {
      child = const SizedBox.shrink();
    } else {
      child = Tooltip(
        message: block.token!.tokenStandard.toString(),
        child: Text(
          block.token!.name,
          style: TextStyle(
            color: ColorUtils.getTokenColor(block.tokenStandard),
          ),
        ),
      );
    }

    return InfiniteScrollTableCell(
      child: child,
    );
  }
}
