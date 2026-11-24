import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Provides confirmation timing information for an [AccountBlock].
extension AccountBlocExtension on AccountBlock {
  /// The confirmation timestamp in milliseconds, or zero if unconfirmed.
  int get confirmationTimestampMs =>
      (confirmationDetail?.momentumTimestamp ?? 0) * 1000;
}
