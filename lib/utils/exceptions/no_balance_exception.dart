/// Custom [Exception] used when there is no balance available on a specific
/// address
class NoBalanceException implements Exception {
  @override
  String toString() => 'Empty balance on the selected address';
}
