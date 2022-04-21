import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/dashboard_base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class NodeSyncStatusBloc extends DashboardBaseBloc<SyncInfo> {
  SyncState lastSyncState = SyncState.unknown;

  @override
  Future<SyncInfo> makeAsyncCall() async {
    if (zenon!.wsClient.status() == WebsocketStatus.running) {
      SyncInfo syncInfo = await zenon!.stats.syncInfo();
      if (lastSyncState != syncInfo.state &&
          (syncInfo.state == SyncState.syncDone ||
              (syncInfo.targetHeight > 0 &&
                  syncInfo.currentHeight > 0 &&
                  (syncInfo.targetHeight - syncInfo.currentHeight) > 3))) {
        lastSyncState = syncInfo.state;
        if (syncInfo.state == SyncState.syncDone) {
          NodeUtils.getUnreceivedTransactions().then((value) {
            sl<AutoReceiveTxWorker>().autoReceive();
          });
          Future.delayed(const Duration(seconds: 5)).then((value) {
            NodeUtils.getUnreceivedTransactions().then((value) {
              sl<AutoReceiveTxWorker>().autoReceive();
            });
          });
        }
      }
      return syncInfo;
    }
    return SyncInfo.fromJson({
      'state': 0,
      'currentHeight': 0,
      'targetHeight': 0,
    });
  }
}
