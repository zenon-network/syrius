/// Mathematical helper utilities for [BigInt] values.
class MathUtils {
  /// Returns the smaller of [a] and [b].
  static BigInt bigMin(BigInt a, BigInt b) {
    if (a <= b) {
      return a;
    }
    return b;
  }

  /// Returns the larger of [a] and [b].
  static BigInt bigMax(BigInt a, BigInt b) {
    if (a <= b) {
      return b;
    }
    return a;
  }
}
