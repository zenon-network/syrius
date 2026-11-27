/// Decoded smart-contract call data extracted from an account block.
class BlockData {
  /// Creates a [BlockData] instance with the decoded [function] and [params].
  BlockData({
    required this.function,
    required this.params,
  });

  /// Name of the invoked embedded contract function.
  final String function;

  /// Map of decoded parameter names to their values.
  final Map<String, dynamic> params;
}
