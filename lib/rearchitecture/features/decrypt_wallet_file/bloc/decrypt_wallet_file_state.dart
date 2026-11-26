part of 'decrypt_wallet_file_bloc.dart';

/// Classifies the user-facing reason a wallet file decryption attempt failed.
enum DecryptWalletFileFailureReason {
  /// The supplied password did not decrypt the keystore.
  incorrectPassword,

  /// The file content is not a valid keystore JSON payload.
  invalidKeystoreFormat,

  /// The selected wallet file path does not exist.
  fileNotFound,

  /// The selected wallet path is not a regular file (e.g. directory or FIFO).
  notRegularFile,

  /// The selected file exceeds the maximum allowed keystore file size.
  fileTooLarge,

  /// The keystore metadata declares an unsupported wallet type.
  unsupportedWalletType,

  /// An unclassified failure occurred while reading or decrypting the file.
  unknown,
}

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
    this.reason = DecryptWalletFileFailureReason.unknown,
  });

  /// Error thrown while reading or decrypting the wallet file.
  final Object error;

  /// Whether [error] is an [IncorrectPasswordException].
  final bool isIncorrectPassword;

  /// Classified failure reason for presentation-layer localization.
  final DecryptWalletFileFailureReason reason;

  @override
  List<Object?> get props => <Object?>[error, isIncorrectPassword, reason];
}
