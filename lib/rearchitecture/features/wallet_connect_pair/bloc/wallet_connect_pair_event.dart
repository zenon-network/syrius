part of 'wallet_connect_pair_bloc.dart';

/// Base event for [WalletConnectPairBloc].
sealed class WalletConnectPairEvent extends Equatable {
  const WalletConnectPairEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initiates a WalletConnect pairing from a raw URI or deep link string.
final class WalletConnectPairRequested extends WalletConnectPairEvent {
  /// Creates a [WalletConnectPairRequested] event.
  const WalletConnectPairRequested({
    required this.rawUri,
    this.isWindows = false,
  });

  /// Raw URI, encoded payload, or `syrius://wc?uri=...` link to pair with.
  final String rawUri;

  /// Whether Windows-style `/?` normalization should be applied when
  /// extracting the WalletConnect URI.
  final bool isWindows;

  @override
  List<Object?> get props => <Object?>[rawUri, isWindows];
}
