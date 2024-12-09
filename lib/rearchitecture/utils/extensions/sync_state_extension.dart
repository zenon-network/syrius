import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Extension on the [SyncState] class
extension SyncStateExtension on SyncState {
  /// Returns a color, depending on the enum value
  Color? getColor({required BuildContext context}) {
    return switch (this) {
      SyncState.unknown => Theme.of(context).iconTheme.color,
      SyncState.syncing => Colors.orange,
      SyncState.syncDone => AppColors.znnColor,
      SyncState.notEnoughPeers => AppColors.errorColor,
    };
  }
}
