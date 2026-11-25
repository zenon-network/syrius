part of 'change_wallet_password_bloc.dart';

/// Base class for [ChangeWalletPasswordBloc] events.
sealed class ChangeWalletPasswordEvent extends Equatable {
  /// Creates a [ChangeWalletPasswordEvent].
  const ChangeWalletPasswordEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests verifying [currentPassword] and re-encrypting the wallet and HTLC
/// swap storage with [newPassword].
final class ChangeWalletPasswordSubmitted extends ChangeWalletPasswordEvent {
  /// Creates a [ChangeWalletPasswordSubmitted] event.
  const ChangeWalletPasswordSubmitted({
    required this.currentPassword,
    required this.newPassword,
    required this.decryptErrorTitle,
    required this.changePasswordErrorTitle,
  });

  /// Existing wallet password entered by the user.
  final String currentPassword;

  /// Desired new wallet password.
  final String newPassword;

  /// Localized error notification title if wallet decryption fails.
  final String decryptErrorTitle;

  /// Localized error notification title if password change or rekey fails.
  final String changePasswordErrorTitle;

  @override
  List<Object?> get props => <Object?>[
    currentPassword,
    newPassword,
    decryptErrorTitle,
    changePasswordErrorTitle,
  ];
}

/// Clears any displayed incorrect-password validation error.
final class ChangeWalletPasswordErrorCleared extends ChangeWalletPasswordEvent {
  /// Creates a [ChangeWalletPasswordErrorCleared] event.
  const ChangeWalletPasswordErrorCleared();
}
