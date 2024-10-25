/// Custom [Exception] used when there are no delegation info available
class NoDelegationStatsException implements Exception {
  @override
  String toString() => 'No delegation stats available';
}
