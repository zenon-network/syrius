part of 'key_store_file_bloc.dart';

/// Base class for keystore wallet file creation states.
sealed class KeyStoreFileState extends Equatable {
  /// Creates a [KeyStoreFileState].
  const KeyStoreFileState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before keystore creation begins.
final class KeyStoreFileInitial extends KeyStoreFileState {
  /// Creates a [KeyStoreFileInitial].
  const KeyStoreFileInitial();
}

/// Loading state while creating and initializing the keystore wallet file.
final class KeyStoreFileLoading extends KeyStoreFileState {
  /// Creates a [KeyStoreFileLoading].
  const KeyStoreFileLoading();
}

/// Success state carrying the created [walletFile].
final class KeyStoreFileSuccess extends KeyStoreFileState {
  /// Creates a [KeyStoreFileSuccess].
  const KeyStoreFileSuccess({required this.walletFile});

  /// The newly created keystore wallet file.
  final KeyStoreWalletFile walletFile;

  @override
  List<Object?> get props => <Object?>[walletFile];
}

/// Failure state emitted when keystore creation or initialization fails.
final class KeyStoreFileFailure extends KeyStoreFileState {
  /// Creates a [KeyStoreFileFailure].
  const KeyStoreFileFailure(this.error);

  /// Error encountered while creating the keystore wallet.
  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
