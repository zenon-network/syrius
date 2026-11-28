/// Computes a Pillar's rounded momentum uptime percentage.
///
/// Returns `0` when [expected] is non-positive, [produced] is negative, or the
/// computed ratio is `NaN` or infinite.
int computeMomentumUptimePercentage(int produced, int expected) {
  if (expected <= 0 || produced < 0) {
    return 0;
  }
  final double percentage = produced / expected * 100;
  if (percentage.isNaN || percentage.isInfinite) {
    return 0;
  }
  return percentage.round();
}
