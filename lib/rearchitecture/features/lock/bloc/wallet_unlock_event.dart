part of 'wallet_unlock_bloc.dart';

/// Base class for wallet unlock events.
sealed class WalletUnlockEvent extends Equatable {
  /// Creates a [WalletUnlockEvent].
  const WalletUnlockEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Submits a password to unlock and optionally initialize the wallet.
final class WalletUnlockSubmitted extends WalletUnlockEvent {
  /// Creates a [WalletUnlockSubmitted] event.
  const WalletUnlockSubmitted({
    required this.password,
    required this.incorrectPasswordTitle,
    required this.unlockFailedTitle,
    required this.ledgerErrorTitleBuilder,
  });

  /// Password entered by the user.
  final String password;

  /// Localized notification title for an incorrect password.
  final String incorrectPasswordTitle;

  /// Localized notification title for a generic unlock failure.
  final String unlockFailedTitle;

  /// Builds a localized notification title for a Ledger error.
  final String Function(String details) ledgerErrorTitleBuilder;

  @override
  List<Object?> get props => <Object?>[
    password,
    incorrectPasswordTitle,
    unlockFailedTitle,
  ];
}
