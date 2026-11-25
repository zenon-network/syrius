part of 'wallet_connect_pairings_bloc.dart';

/// State managed by [WalletConnectPairingsBloc].
final class WalletConnectPairingsState extends Equatable {
  /// Creates a [WalletConnectPairingsState].
  const WalletConnectPairingsState({
    this.pairings = const <PairingInfo>[],
    this.deactivatingTopics = const <String>{},
    this.error,
    this.errorCount = 0,
  });

  /// Currently active and inactive WalletConnect pairings.
  final List<PairingInfo> pairings;

  /// Pairing topics currently being deactivated.
  final Set<String> deactivatingTopics;

  /// Most recent deactivation error, if any.
  final Object? error;

  /// Monotonically incremented each time a deactivation error is emitted so
  /// listeners receive distinct notifications even for equal concurrent errors.
  final int errorCount;

  /// Returns a copy of this state with the provided fields replaced.
  WalletConnectPairingsState copyWith({
    List<PairingInfo>? pairings,
    Set<String>? deactivatingTopics,
    Object? error,
    int? errorCount,
    bool clearError = false,
  }) {
    return WalletConnectPairingsState(
      pairings: pairings ?? this.pairings,
      deactivatingTopics: deactivatingTopics ?? this.deactivatingTopics,
      error: clearError ? null : (error ?? this.error),
      errorCount: errorCount ?? this.errorCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    pairings,
    deactivatingTopics,
    error,
    errorCount,
  ];
}
