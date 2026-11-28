import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Minimum Pillar reward-sharing percentage (`0%`).
const int kMinPillarRewardPercentage = 0;

/// Maximum Pillar reward-sharing percentage (`100%`).
const int kMaxPillarRewardPercentage = 100;

/// Returns whether [znnBalance] meets [kMinDelegationAmount] (`1 ZNN`) to
/// delegate to a Pillar.
bool canDelegateWithZnnBalance(BigInt znnBalance) =>
    znnBalance >= kMinDelegationAmount;

/// Returns whether [percentage] is within the valid `[0, 100]` Pillar
/// reward-sharing range.
bool isValidPillarRewardPercentage(int percentage) =>
    percentage >= kMinPillarRewardPercentage &&
    percentage <= kMaxPillarRewardPercentage;

/// Computes the Pillar owner's retained reward percentage (`100 - delegate`)
/// for a valid [delegatePercentage], or `0` if out of bounds.
int computeOwnerRewardPercentage(int delegatePercentage) =>
    isValidPillarRewardPercentage(delegatePercentage)
    ? kMaxPillarRewardPercentage - delegatePercentage
    : 0;

/// Returns whether [reward] has positive uncollected ZNN Pillar rewards.
bool canCollectPillarRewards(UncollectedReward reward) =>
    reward.znnAmount > BigInt.zero;

/// Returns whether [reward] has positive uncollected ZNN or QSR Sentinel
/// rewards.
bool canCollectSentinelRewards(UncollectedReward reward) =>
    reward.znnAmount > BigInt.zero || reward.qsrAmount > BigInt.zero;

/// Returns whether any Pillar reward history entry contains positive ZNN.
bool hasPillarRewardHistory(List<RewardHistoryEntry> entries) =>
    entries.any((RewardHistoryEntry entry) => entry.znnAmount > BigInt.zero);

/// Returns whether any Sentinel reward history entry contains positive ZNN or
/// QSR.
bool hasSentinelRewardHistory(List<RewardHistoryEntry> entries) => entries.any(
  (RewardHistoryEntry entry) =>
      entry.znnAmount > BigInt.zero || entry.qsrAmount > BigInt.zero,
);

/// Returns whether [currentPlasma] meets [requiredPlasma] for spawning a node.
bool hasSufficientSpawnPlasma({
  required int currentPlasma,
  required int requiredPlasma,
}) => currentPlasma >= requiredPlasma;

/// Returns whether [znnBalance] meets [requiredZnn] collateral for spawning a
/// node.
bool hasSufficientSpawnZnn({
  required BigInt znnBalance,
  required BigInt requiredZnn,
}) => znnBalance >= requiredZnn;
