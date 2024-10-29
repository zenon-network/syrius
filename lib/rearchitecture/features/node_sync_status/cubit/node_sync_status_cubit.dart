import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' hide zenon;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'node_sync_status_cubit.g.dart';

part 'node_sync_status_state.dart';

/// Cubit responsible for fetching the sync state - [SyncState] - and sending
/// the states update - [NodeSyncStatusState] - back to the widget
///
/// [SyncState] is not related to [NodeSyncStatusState], doesn't handle UI
/// updates.
///
/// [NodeSyncStatusState] along with [TimerStatus] updates the UI of the
/// [NodeSyncStatusIcon] widget
class NodeSyncStatusCubit
    extends TimerCubit<Pair<SyncState, SyncInfo>, NodeSyncStatusState> {
  /// Creates a NodeSyncStatusCubit using the super-initializer parameters
  NodeSyncStatusCubit({
    required super.zenon,
    super.initialState = const NodeSyncStatusState(),
  }) : super(
          refreshInterval: kNodeSyncStatusRefreshInterval,
        );

  SyncState _lastSyncState = SyncState.unknown;

  @override
  Future<Pair<SyncState, SyncInfo>> fetch() async {
    if (zenon.wsClient.status() == WebsocketStatus.running) {
      final SyncInfo syncInfo = await zenon.stats.syncInfo();
      if (_lastSyncState != syncInfo.state &&
          (syncInfo.state == SyncState.syncDone ||
              (syncInfo.targetHeight > 0 &&
                  syncInfo.currentHeight > 0 &&
                  (syncInfo.targetHeight - syncInfo.currentHeight) > 3))) {
        _lastSyncState = syncInfo.state;
        if (syncInfo.state == SyncState.syncDone) {
          unawaited(
            Future<void>.delayed(const Duration(seconds: 5)).then((_) {
              NodeUtils.getUnreceivedTransactions().then((_) {
                sl<AutoReceiveTxWorker>().autoReceive();
              });
            }),
          );
        }
      }
      return Pair<SyncState, SyncInfo>(_lastSyncState, syncInfo);
    }

    final SyncInfo placeholderSyncInfo = SyncInfo.fromJson(<String, dynamic>{
      'state': 0,
      'currentHeight': 0,
      'targetHeight': 0,
    });
    return Pair<SyncState, SyncInfo>(_lastSyncState, placeholderSyncInfo);
  }

  @override
  NodeSyncStatusState? fromJson(Map<String, dynamic> json) =>
      NodeSyncStatusState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(NodeSyncStatusState state) => state.toJson();
}
