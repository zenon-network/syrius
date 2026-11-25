part of 'decrypt_wallet_file_bloc.dart';

/// Base class for wallet file decryption events.
sealed class DecryptWalletFileEvent extends Equatable {
  /// Creates a [DecryptWalletFileEvent].
  const DecryptWalletFileEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests decryption of the wallet file at [path] using [password].
final class DecryptWalletFileRequested extends DecryptWalletFileEvent {
  /// Creates a [DecryptWalletFileRequested] event.
  const DecryptWalletFileRequested({
    required this.path,
    required this.password,
  });

  /// Filesystem path of the encrypted wallet file.
  final String path;

  /// Password used to decrypt the wallet file.
  final String password;

  @override
  List<Object> get props => <Object>[path, password];
}
