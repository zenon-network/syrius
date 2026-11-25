part of 'change_wallet_password_bloc.dart';

/// Base state for [ChangeWalletPasswordBloc].
sealed class ChangeWalletPasswordState extends Equatable {
  /// Creates a [ChangeWalletPasswordState].
  const ChangeWalletPasswordState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Idle state ready for password submission.
final class ChangeWalletPasswordInitial extends ChangeWalletPasswordState {
  /// Creates a [ChangeWalletPasswordInitial] state.
  const ChangeWalletPasswordInitial();
}

/// State emitted while decrypting, migrating legacy swaps, rekeying, and
/// changing the wallet password.
final class ChangeWalletPasswordLoading extends ChangeWalletPasswordState {
  /// Creates a [ChangeWalletPasswordLoading] state.
  const ChangeWalletPasswordLoading();
}

/// State emitted when the supplied current password is incorrect.
final class ChangeWalletPasswordIncorrectCurrentPassword
    extends ChangeWalletPasswordState {
  /// Creates a [ChangeWalletPasswordIncorrectCurrentPassword] state.
  const ChangeWalletPasswordIncorrectCurrentPassword();
}

/// State emitted when password change and swap storage rekeying succeeded.
final class ChangeWalletPasswordSuccess extends ChangeWalletPasswordState {
  /// Creates a [ChangeWalletPasswordSuccess] state.
  const ChangeWalletPasswordSuccess();
}

/// State emitted when decryption or password change failed unexpectedly.
final class ChangeWalletPasswordFailure extends ChangeWalletPasswordState {
  /// Creates a [ChangeWalletPasswordFailure] state.
  const ChangeWalletPasswordFailure({required this.error});

  /// Error encountered during decryption or rekeying.
  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
