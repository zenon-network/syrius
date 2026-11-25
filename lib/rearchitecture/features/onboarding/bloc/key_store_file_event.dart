part of 'key_store_file_bloc.dart';

/// Base class for keystore wallet file creation events.
sealed class KeyStoreFileEvent extends Equatable {
  /// Creates a [KeyStoreFileEvent].
  const KeyStoreFileEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests creating a keystore wallet file and initializing the wallet.
final class KeyStoreFileCreateRequested extends KeyStoreFileEvent {
  /// Creates a [KeyStoreFileCreateRequested] event.
  const KeyStoreFileCreateRequested({
    required this.mnemonic,
    required this.password,
  });

  /// BIP-39 mnemonic phrase for the wallet.
  final String mnemonic;

  /// Encryption password for the keystore file.
  final String password;

  @override
  List<Object> get props => <Object>[mnemonic, password];
}
