part of 'wallet_connect_sessions_bloc.dart';

/// Base event for [WalletConnectSessionsBloc].
sealed class WalletConnectSessionsEvent extends Equatable {
  const WalletConnectSessionsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Reloads the current WalletConnect sessions snapshot.
final class WalletConnectSessionsRefreshRequested
    extends WalletConnectSessionsEvent {
  /// Creates a [WalletConnectSessionsRefreshRequested] event.
  const WalletConnectSessionsRefreshRequested();
}

/// Requests disconnection of the WalletConnect session identified by [topic].
final class WalletConnectSessionDisconnectRequested
    extends WalletConnectSessionsEvent {
  /// Creates a [WalletConnectSessionDisconnectRequested] event.
  const WalletConnectSessionDisconnectRequested({required this.topic});

  /// Session topic to disconnect.
  final String topic;

  @override
  List<Object?> get props => <Object?>[topic];
}

final class _WalletConnectSessionsUpdated extends WalletConnectSessionsEvent {
  const _WalletConnectSessionsUpdated(this._sessions);

  final List<SessionData> _sessions;

  @override
  List<Object?> get props => <Object?>[_sessions];
}
