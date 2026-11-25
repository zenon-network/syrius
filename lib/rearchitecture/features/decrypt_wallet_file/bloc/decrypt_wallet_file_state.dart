part of 'decrypt_wallet_file_bloc.dart';

/// Base class for wallet file decryption states.
sealed class DecryptWalletFileState extends Equatable {
  /// Creates a [DecryptWalletFileState].
  const DecryptWalletFileState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before any decryption request.
final class DecryptWalletFileInitial extends DecryptWalletFileState {
  /// Creates a [DecryptWalletFileInitial].
  const DecryptWalletFileInitial();
}

/// Loading state emitted while decrypting a wallet file.
final class DecryptWalletFileLoading extends DecryptWalletFileState {
  /// Creates a [DecryptWalletFileLoading].
  const DecryptWalletFileLoading();
}

/// Success state carrying the decrypted [walletFile].
final class DecryptWalletFileSuccess extends DecryptWalletFileState {
  /// Creates a [DecryptWalletFileSuccess].
  const DecryptWalletFileSuccess({required this.walletFile});

  /// The decrypted wallet file.
  final WalletFile walletFile;

  @override
  List<Object?> get props => <Object?>[walletFile];
}

/// Failure state emitted when wallet file decryption fails.
final class DecryptWalletFileFailure extends DecryptWalletFileState {
  /// Creates a [DecryptWalletFileFailure].
  const DecryptWalletFileFailure({
    required this.error,
    required this.isIncorrectPassword,
  });

  /// Error thrown while reading or decrypting the wallet file.
  final Object error;

  /// Whether [error] is an [IncorrectPasswordException].
  final bool isIncorrectPassword;

  @override
  List<Object?> get props => <Object?>[error, isIncorrectPassword];
}
