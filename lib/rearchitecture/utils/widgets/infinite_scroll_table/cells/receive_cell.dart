import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveCell extends StatelessWidget {
  const ReceiveCell({required this.hash, super.key});

  final Hash hash;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableCell(
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: context.l10n.pressToReceive,
          icon: const Icon(Icons.call_received_rounded),
          color: AppColors.znnColor,
          onPressed: () {
            sl<AutoReceiveTxWorker>().autoReceiveTransactionHash(
              hash,
            );
          },
        ),
      ),
    );
  }
}
