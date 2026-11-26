/// Contract describing a WalletConnect chain namespace, identifier, and
/// supported session events.
abstract class IChain {
  /// Returns the WalletConnect namespace (for example, `'zenon'`).
  String getNamespace();

  /// Returns the CAIP-2 chain identifier (for example, `'zenon:1'`).
  String getChainId();

  /// Returns the list of WalletConnect events emitted for this chain.
  List<String> getEvents();
}
