part of 'wallet_connect_pairings_bloc.dart';

/// Base event for [WalletConnectPairingsBloc].
sealed class WalletConnectPairingsEvent extends Equatable {
  const WalletConnectPairingsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Reloads the current WalletConnect pairings snapshot.
final class WalletConnectPairingsRefreshRequested
    extends WalletConnectPairingsEvent {
  /// Creates a [WalletConnectPairingsRefreshRequested] event.
  const WalletConnectPairingsRefreshRequested();
}

/// Requests deactivation of the WalletConnect pairing identified by [topic].
final class WalletConnectPairingDeactivateRequested
    extends WalletConnectPairingsEvent {
  /// Creates a [WalletConnectPairingDeactivateRequested] event.
  const WalletConnectPairingDeactivateRequested({required this.topic});

  /// Pairing topic to deactivate.
  final String topic;

  @override
  List<Object?> get props => <Object?>[topic];
}

final class _WalletConnectPairingsUpdated extends WalletConnectPairingsEvent {
  const _WalletConnectPairingsUpdated(this._pairings);

  final List<PairingInfo> _pairings;

  @override
  List<Object?> get props => <Object?>[_pairings];
}
