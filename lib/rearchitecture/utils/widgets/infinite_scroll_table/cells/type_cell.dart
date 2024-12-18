import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TypeCell extends StatelessWidget {
  const TypeCell({required this.block, super.key});

  final AccountBlock block;

  @override
  Widget build(BuildContext context) {
    late final Widget child;

    if (BlockUtils.isSendBlock(block.blockType)) {
      child = Tooltip(
        message: context.l10n.send,
        child: const Icon(
          Icons.call_made_rounded,
          color: AppColors.errorColor,
        ),
      );
    } else {
      child = Tooltip(
        message: context.l10n.receive,
        child: const Icon(
          Icons.call_received_rounded,
          color: AppColors.znnColor,
        ),
      );
    }

    return InfiniteScrollTableCell(
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}
