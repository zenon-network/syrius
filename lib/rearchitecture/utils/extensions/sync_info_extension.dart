import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const int _kSyncHeightTolerance = 3;

/// Adds sync-status interpretation to [SyncInfo].
extension SyncInfoExtension on SyncInfo {
  /// Whether the node is synced or fewer than three momentums behind.
  bool get isSynced =>
      state == SyncState.syncDone ||
      (_hasValidHeights && _heightDifference < _kSyncHeightTolerance);

  /// Whether the node is at least three momentums behind.
  bool get isClearlyBehind =>
      _hasValidHeights && _heightDifference >= _kSyncHeightTolerance;

  bool get _hasValidHeights => targetHeight > 0 && currentHeight > 0;

  int get _heightDifference => targetHeight - currentHeight;
}
