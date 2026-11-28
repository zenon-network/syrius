import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Returns whether [reward] has positive uncollected QSR staking rewards
/// available to collect.
bool canCollectStakeRewards(UncollectedReward reward) =>
    reward.qsrAmount > BigInt.zero;
