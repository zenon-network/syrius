import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' hide zenon;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/node_sync_status/node_sync_status.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'node_sync_status_state.dart';

/// Cubit responsible for fetching the sync state - [SyncState] - and sending
/// the states update - [NodeSyncStatusState] - back to the widget
///
/// [SyncState] is not related to [NodeSyncStatusState], doesn't handle UI updates
///
/// [NodeSyncStatusState] along with [DashboardStatus] updates the UI of the
/// [NodeSyncStatusIcon] widget
class NodeSyncStatusCubit
    extends DashboardCubit<Pair<SyncState, SyncInfo>, NodeSyncStatusState> {
  NodeSyncStatusCubit(super.zenon, super.initialState);

  SyncState _lastSyncState = SyncState.unknown;

  @override
  Future<Pair<SyncState, SyncInfo>> fetch() async {
    if (zenon.wsClient.status() == WebsocketStatus.running) {
      final syncInfo = await zenon.stats.syncInfo();
      if (_lastSyncState != syncInfo.state &&
          (syncInfo.state == SyncState.syncDone ||
              (syncInfo.targetHeight > 0 &&
                  syncInfo.currentHeight > 0 &&
                  (syncInfo.targetHeight - syncInfo.currentHeight) > 3))) {
        _lastSyncState = syncInfo.state;
        if (syncInfo.state == SyncState.syncDone) {
          unawaited(
            Future.delayed(const Duration(seconds: 5)).then((_) {
              NodeUtils.getUnreceivedTransactions().then((_) {
                sl<AutoReceiveTxWorker>().autoReceive();
              });
            }),
          );
        }
      }
      return Pair(_lastSyncState, syncInfo);
    }

    final placeholderSyncInfo = SyncInfo.fromJson({
      'state': 0,
      'currentHeight': 0,
      'targetHeight': 0,
    });
    return Pair(_lastSyncState, placeholderSyncInfo);
  }
}
