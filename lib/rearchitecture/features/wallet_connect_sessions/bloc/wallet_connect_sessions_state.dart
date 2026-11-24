part of 'wallet_connect_sessions_bloc.dart';

/// State managed by [WalletConnectSessionsBloc].
final class WalletConnectSessionsState extends Equatable {
  /// Creates a [WalletConnectSessionsState].
  const WalletConnectSessionsState({
    this.sessions = const <SessionData>[],
    this.disconnectingTopics = const <String>{},
    this.error,
    this.errorCount = 0,
  });

  /// Currently active WalletConnect sessions.
  final List<SessionData> sessions;

  /// Session topics currently being disconnected.
  final Set<String> disconnectingTopics;

  /// Most recent disconnection error, if any.
  final Object? error;

  /// Monotonically incremented each time a disconnection error is emitted so
  /// listeners receive distinct notifications even for equal concurrent errors.
  final int errorCount;

  /// Returns a copy of this state with the provided fields replaced.
  WalletConnectSessionsState copyWith({
    List<SessionData>? sessions,
    Set<String>? disconnectingTopics,
    Object? error,
    int? errorCount,
    bool clearError = false,
  }) {
    return WalletConnectSessionsState(
      sessions: sessions ?? this.sessions,
      disconnectingTopics: disconnectingTopics ?? this.disconnectingTopics,
      error: clearError ? null : (error ?? this.error),
      errorCount: errorCount ?? this.errorCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sessions,
    disconnectingTopics,
    error,
    errorCount,
  ];
}
