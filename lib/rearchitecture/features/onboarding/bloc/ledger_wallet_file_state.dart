part of 'ledger_wallet_file_bloc.dart';

/// Base class for Ledger wallet file creation states.
sealed class LedgerWalletFileState extends Equatable {
  /// Creates a [LedgerWalletFileState].
  const LedgerWalletFileState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before Ledger wallet creation begins.
final class LedgerWalletFileInitial extends LedgerWalletFileState {
  /// Creates a [LedgerWalletFileInitial].
  const LedgerWalletFileInitial();
}

/// Loading state while creating and initializing the Ledger wallet file.
final class LedgerWalletFileLoading extends LedgerWalletFileState {
  /// Creates a [LedgerWalletFileLoading].
  const LedgerWalletFileLoading();
}

/// Success state carrying the created [walletFile].
final class LedgerWalletFileSuccess extends LedgerWalletFileState {
  /// Creates a [LedgerWalletFileSuccess].
  const LedgerWalletFileSuccess({required this.walletFile});

  /// The newly created Ledger wallet file.
  final LedgerWalletFile walletFile;

  @override
  List<Object?> get props => <Object?>[walletFile];
}

/// Failure state emitted when Ledger wallet creation or initialization fails.
final class LedgerWalletFileFailure extends LedgerWalletFileState {
  /// Creates a [LedgerWalletFileFailure].
  const LedgerWalletFileFailure(this.error);

  /// Error encountered while creating the Ledger wallet.
  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
