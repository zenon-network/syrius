import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/sync_info_extension.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Provides current node sync information while coalescing concurrent requests.
class NodeSyncMonitor {
  /// Creates a monitor backed by the provided Zenon client.
  NodeSyncMonitor({required this._zenon});

  final Zenon _zenon;
  final Logger _logger = Logger('NodeSyncMonitor');

  Future<SyncInfo>? _inFlightRequest;

  /// Fetches current sync information, sharing any request already in flight.
  Future<SyncInfo> fetch() => _inFlightRequest ??= _fetch();

  /// Whether the node is synced or fewer than three momentums behind.
  Future<bool> isNodeSynced() async {
    try {
      final SyncInfo syncInfo = await fetch();
      return syncInfo.isSynced;
    } on Object catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'isNodeSynced', error, stackTrace);
      return false;
    }
  }

  Future<SyncInfo> _fetch() async {
    try {
      return await Future<SyncInfo>.sync(_zenon.stats.syncInfo);
    } finally {
      _inFlightRequest = null;
    }
  }
}
