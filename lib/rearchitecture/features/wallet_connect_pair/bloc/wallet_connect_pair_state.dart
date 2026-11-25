part of 'wallet_connect_pair_bloc.dart';

/// Lifecycle status for a WalletConnect pairing request.
enum WalletConnectPairStatus {
  /// No pairing attempt has started yet.
  initial,

  /// A pairing request is currently in progress.
  loading,

  /// The most recent pairing request succeeded.
  success,

  /// The most recent pairing request failed.
  failure,
}

/// State managed by [WalletConnectPairBloc].
final class WalletConnectPairState extends Equatable {
  /// Creates a [WalletConnectPairState].
  const WalletConnectPairState({
    this.status = WalletConnectPairStatus.initial,
    this.pairingInfo,
    this.error,
    this.successCount = 0,
    this.errorCount = 0,
  });

  /// Current pairing operation status.
  final WalletConnectPairStatus status;

  /// Most recently created [PairingInfo], if any.
  final PairingInfo? pairingInfo;

  /// Most recent pairing error, if any.
  final Object? error;

  /// Monotonically incremented on each successful pairing so listeners react
  /// to repeated pairings reliably.
  final int successCount;

  /// Monotonically incremented on each pairing error so listeners react even
  /// when consecutive errors compare equal.
  final int errorCount;

  /// Returns a copy of this state with the provided fields replaced.
  WalletConnectPairState copyWith({
    WalletConnectPairStatus? status,
    PairingInfo? pairingInfo,
    Object? error,
    int? successCount,
    int? errorCount,
    bool clearError = false,
  }) {
    return WalletConnectPairState(
      status: status ?? this.status,
      pairingInfo: pairingInfo ?? this.pairingInfo,
      error: clearError ? null : (error ?? this.error),
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    pairingInfo,
    error,
    successCount,
    errorCount,
  ];
}
