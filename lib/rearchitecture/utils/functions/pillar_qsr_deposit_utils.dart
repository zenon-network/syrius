import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/math_utils.dart';

/// Derived QSR deposit state for Pillar and Sentinel creation steps.
class PillarQsrDepositSummary extends Equatable {
  /// Creates a [PillarQsrDepositSummary].
  const PillarQsrDepositSummary({
    required this.remaining,
    required this.maxDeposit,
    required this.isCovered,
    required this.canWithdraw,
    required this.clampedDeposit,
    required this.depositedFraction,
    required this.remainingFraction,
  });

  /// Additional QSR needed to reach the required cost (`0` once covered).
  final BigInt remaining;

  /// Maximum QSR that can be deposited right now: `min(qsrBalance, remaining)`.
  final BigInt maxDeposit;

  /// Whether the existing deposit meets or exceeds the required QSR cost.
  final bool isCovered;

  /// Whether any deposited QSR is available to withdraw (`qsrDeposit > 0`).
  final bool canWithdraw;

  /// Existing deposit clamped to `[0, effectiveCost]` for progress display.
  final BigInt clampedDeposit;

  /// Clamped fraction of required QSR already deposited, in `[0.0, 1.0]`.
  final double depositedFraction;

  /// Clamped fraction of required QSR still remaining, in `[0.0, 1.0]`.
  final double remainingFraction;

  @override
  List<Object> get props => <Object>[
    remaining,
    maxDeposit,
    isCovered,
    canWithdraw,
    clampedDeposit,
    depositedFraction,
    remainingFraction,
  ];
}

/// Computes QSR deposit bounds, coverage, withdrawal eligibility, and progress
/// fractions for Pillar and Sentinel slot registration.
PillarQsrDepositSummary computePillarQsrDepositSummary({
  required BigInt qsrBalance,
  required BigInt qsrCost,
  required BigInt qsrDeposit,
}) {
  final BigInt effectiveBalance = MathUtils.bigMax(BigInt.zero, qsrBalance);
  final BigInt effectiveCost = MathUtils.bigMax(BigInt.zero, qsrCost);
  final BigInt effectiveDeposit = MathUtils.bigMax(BigInt.zero, qsrDeposit);

  final BigInt remaining = MathUtils.bigMax(
    BigInt.zero,
    effectiveCost - effectiveDeposit,
  );
  final BigInt maxDeposit = MathUtils.bigMin(effectiveBalance, remaining);
  final bool isCovered = effectiveDeposit >= effectiveCost;
  final bool canWithdraw = effectiveDeposit > BigInt.zero;
  final BigInt clampedDeposit = MathUtils.bigMin(
    effectiveDeposit,
    effectiveCost,
  );

  final double depositedFraction = effectiveCost > BigInt.zero
      ? (clampedDeposit / effectiveCost).clamp(0.0, 1.0)
      : 0.0;
  final double remainingFraction = effectiveCost > BigInt.zero
      ? (remaining / effectiveCost).clamp(0.0, 1.0 - depositedFraction)
      : 0.0;

  return PillarQsrDepositSummary(
    remaining: remaining,
    maxDeposit: maxDeposit,
    isCovered: isCovered,
    canWithdraw: canWithdraw,
    clampedDeposit: clampedDeposit,
    depositedFraction: depositedFraction,
    remainingFraction: remainingFraction,
  );
}
