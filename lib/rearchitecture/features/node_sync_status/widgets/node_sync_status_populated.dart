import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget associated with the [NodeSyncStatusState] when it's status is
/// [TimerStatus.success] that returns a corresponding icon depending on the
/// [SyncInfo] and [SyncState] data
class NodeSyncPopulated extends StatelessWidget {
  /// Creates a NodeSyncPopulated object.
  const NodeSyncPopulated({required this.data, super.key});

  /// A Pair holding detailed info about the sync stage
  final Pair<SyncState, SyncInfo> data;

  @override
  Widget build(BuildContext context) {
    var (SyncState syncState, SyncInfo syncInfo) = (data.first, data.second);

    String message = '';

    if (syncState == SyncState.unknown) {
      message = 'Not ready';
      return Tooltip(
        message: message,
        child: Icon(
          Icons.sync_disabled,
          size: 24,
          color: syncState.getColor(context: context),
        ),
      );
    } else if (syncState == SyncState.syncing) {
      if (syncInfo.targetHeight > 0 &&
          syncInfo.currentHeight > 0 &&
          (syncInfo.targetHeight - syncInfo.currentHeight) < 3) {
        message = 'Connected and synced';
        syncState = SyncState.syncDone;
        return Tooltip(
          message: message,
          child: Icon(
            Icons.radio_button_unchecked,
            size: 24,
            color: syncState.getColor(context: context),
          ),
        );
      } else if (syncInfo.targetHeight == 0 || syncInfo.currentHeight == 0) {
        message = 'Started syncing with the network, please wait';
        syncState = SyncState.syncing;
        return Tooltip(
          message: message,
          child: Icon(
            Icons.sync,
            size: 24,
            color: syncState.getColor(context: context),
          ),
        );
      } else {
        message = 'Sync progress: momentum ${syncInfo.currentHeight} of '
            '${syncInfo.targetHeight}';
        return Tooltip(
          message: message,
          child: SizedBox.square(
            dimension: 18,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).iconTheme.color,
                color: syncState.getColor(context: context),
                value: syncInfo.currentHeight / syncInfo.targetHeight,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      }
    } else if (syncState == SyncState.notEnoughPeers) {
      if (syncInfo.targetHeight > 0 &&
          syncInfo.currentHeight > 0 &&
          (syncInfo.targetHeight - syncInfo.currentHeight) < 20) {
        message = 'Connecting to peers';
        syncState = SyncState.syncing;
        return Tooltip(
          message: message,
          child: SizedBox.square(
            dimension: 18,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).iconTheme.color,
                color: syncState.getColor(context: context),
                value: syncInfo.currentHeight / syncInfo.targetHeight,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      } else if (syncInfo.targetHeight == 0 || syncInfo.currentHeight == 0) {
        message = 'Connecting to peers, please wait';
        syncState = SyncState.syncing;
        return Tooltip(
          message: message,
          child: Icon(
            Icons.sync,
            size: 24,
            color: syncState.getColor(context: context),
          ),
        );
      } else {
        message = 'Sync progress: momentum ${syncInfo.currentHeight} of '
            '${syncInfo.targetHeight}';
        syncState = SyncState.syncing;
        return Tooltip(
          message: message,
          child: SizedBox.square(
            dimension: 18,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Theme.of(context).iconTheme.color,
                color: syncState.getColor(context: context),
                value: syncInfo.currentHeight / syncInfo.targetHeight,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      }
    } else {
      message = 'Connected and synced';
      syncState = SyncState.syncDone;
    }

    return Tooltip(
      message: message,
      child: SizedBox.square(
        dimension: 18,
        child: Center(
          child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).iconTheme.color,
            color: syncState.getColor(context: context),
            value: 1,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
