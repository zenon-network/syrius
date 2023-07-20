class MathUtils {
  static BigInt bigMin(BigInt a, BigInt b) {
    if (a <= b) {
      return a;
    }
    return b;
  }

  static BigInt bigMax(BigInt a, BigInt b) {
    if (a <= b) {
      return b;
    }
    return a;
  }
}
