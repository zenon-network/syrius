part of 'ledger_wallet_file_bloc.dart';

/// Base class for Ledger wallet file creation events.
sealed class LedgerWalletFileEvent extends Equatable {
  /// Creates a [LedgerWalletFileEvent].
  const LedgerWalletFileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests creating a Ledger wallet file and initializing the wallet.
final class LedgerWalletFileCreateRequested extends LedgerWalletFileEvent {
  /// Creates a [LedgerWalletFileCreateRequested] event.
  const LedgerWalletFileCreateRequested({
    required this.walletId,
    required this.password,
    this.walletName,
  });

  /// Identifier of the connected Ledger hardware device.
  final String walletId;

  /// Encryption password for the local Ledger wallet file.
  final String password;

  /// Optional friendly name for the Ledger device.
  final String? walletName;

  @override
  List<Object?> get props => <Object?>[walletId, password, walletName];
}
