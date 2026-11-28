import 'package:equatable/equatable.dart';

/// Derived quorum, majority, and progress-bar span metrics for Accelerator-Z
/// project and phase voting.
class AcceleratorVoteSummary extends Equatable {
  /// Creates an [AcceleratorVoteSummary].
  const AcceleratorVoteSummary({
    required this.yesVotes,
    required this.noVotes,
    required this.totalVotes,
    required this.decisiveVotes,
    required this.totalPillars,
    required this.quorumNeeded,
    required this.votesToAchieveQuorum,
    required this.pillarsThatCanStillVote,
    required this.hasMajority,
    required this.quorumReached,
    required this.yesFraction,
    required this.noFraction,
    required this.quorumFraction,
    required this.remainingQuorumFraction,
    required this.remainingPillarsFraction,
  });

  /// Non-negative Yes vote count.
  final int yesVotes;

  /// Non-negative No vote count.
  final int noVotes;

  /// Non-negative total vote count (Yes + No + Abstain).
  final int totalVotes;

  /// Sum of [yesVotes] and [noVotes].
  final int decisiveVotes;

  /// Non-negative active Pillar count.
  final int totalPillars;

  /// Votes required for quorum: `0` if `totalPillars == 0`, else
  /// `(totalPillars * 33) ~/ 100 + 1`.
  final int quorumNeeded;

  /// Additional votes required to reach quorum, clamped to `[0, totalPillars]`.
  final int votesToAchieveQuorum;

  /// Remaining Pillars beyond quorum threshold that can still vote.
  final int pillarsThatCanStillVote;

  /// Whether Yes votes strictly exceed No votes (`yesVotes > noVotes`).
  final bool hasMajority;

  /// Whether active Pillars exist and `totalVotes >= quorumNeeded`.
  final bool quorumReached;

  /// Fraction of decisive votes that are Yes, in `[0.0, 1.0]`.
  final double yesFraction;

  /// Fraction of decisive votes that are No, in `[0.0, 1.0]`.
  final double noFraction;

  /// Clamped fraction of total Pillars that have voted, in `[0.0, 1.0]`.
  final double quorumFraction;

  /// Clamped fraction of total Pillars still needed for quorum, in
  /// `[0.0, 1.0]`.
  final double remainingQuorumFraction;

  /// Clamped fraction of remaining Pillars beyond quorum, in `[0.0, 1.0]`.
  final double remainingPillarsFraction;

  @override
  List<Object> get props => <Object>[
    yesVotes,
    noVotes,
    totalVotes,
    decisiveVotes,
    totalPillars,
    quorumNeeded,
    votesToAchieveQuorum,
    pillarsThatCanStillVote,
    hasMajority,
    quorumReached,
    yesFraction,
    noFraction,
    quorumFraction,
    remainingQuorumFraction,
    remainingPillarsFraction,
  ];
}

/// Computes quorum requirements, majority status, and clamped progress-bar
/// fractions for an Accelerator-Z vote tally.
AcceleratorVoteSummary computeAcceleratorVoteSummary({
  required int yes,
  required int no,
  required int total,
  required int totalPillars,
}) {
  final int safeYes = yes < 0 ? 0 : yes;
  final int safeNo = no < 0 ? 0 : no;
  final int safeTotal = total < 0 ? 0 : total;
  final int safePillars = totalPillars < 0 ? 0 : totalPillars;
  final int decisiveVotes = safeYes + safeNo;

  final int quorumNeeded = safePillars > 0
      ? (safePillars * 33) ~/ 100 + 1
      : 0;
  final int votesToAchieveQuorum = safePillars > 0
      ? (quorumNeeded - safeTotal).clamp(0, safePillars)
      : 0;
  final int pillarsThatCanStillVote = safePillars > 0
      ? (safePillars - safeTotal - votesToAchieveQuorum).clamp(0, safePillars)
      : 0;

  final double yesFraction = decisiveVotes > 0 ? safeYes / decisiveVotes : 0.0;
  final double noFraction = decisiveVotes > 0 ? safeNo / decisiveVotes : 0.0;
  final double quorumFraction = safePillars > 0
      ? (safeTotal / safePillars).clamp(0.0, 1.0)
      : 0.0;
  final double remainingQuorumFraction = safePillars > 0
      ? (votesToAchieveQuorum / safePillars).clamp(0.0, 1.0 - quorumFraction)
      : 0.0;
  final double remainingPillarsFraction = safePillars > 0
      ? (pillarsThatCanStillVote / safePillars).clamp(
          0.0,
          1.0 - quorumFraction - remainingQuorumFraction,
        )
      : 0.0;

  return AcceleratorVoteSummary(
    yesVotes: safeYes,
    noVotes: safeNo,
    totalVotes: safeTotal,
    decisiveVotes: decisiveVotes,
    totalPillars: safePillars,
    quorumNeeded: quorumNeeded,
    votesToAchieveQuorum: votesToAchieveQuorum,
    pillarsThatCanStillVote: pillarsThatCanStillVote,
    hasMajority: safeYes > safeNo,
    quorumReached: safePillars > 0 && safeTotal >= quorumNeeded,
    yesFraction: yesFraction,
    noFraction: noFraction,
    quorumFraction: quorumFraction,
    remainingQuorumFraction: remainingQuorumFraction,
    remainingPillarsFraction: remainingPillarsFraction,
  );
}
