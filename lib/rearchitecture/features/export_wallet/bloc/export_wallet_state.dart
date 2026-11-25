part of 'export_wallet_bloc.dart';

/// Base state for [ExportWalletBloc].
sealed class ExportWalletState extends Equatable {
  /// Creates an [ExportWalletState].
  const ExportWalletState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Idle state ready for export submission.
final class ExportWalletInitial extends ExportWalletState {
  /// Creates an [ExportWalletInitial] state.
  const ExportWalletInitial();
}

/// State emitted while choosing a save path and writing the encrypted file.
final class ExportWalletLoading extends ExportWalletState {
  /// Creates an [ExportWalletLoading] state.
  const ExportWalletLoading();
}

/// State emitted when the Seed Vault file was saved successfully.
final class ExportWalletSuccess extends ExportWalletState {
  /// Creates an [ExportWalletSuccess] state.
  const ExportWalletSuccess({
    required this.savedPath,
    required this.backupWalletFlow,
  });

  /// Filesystem path where the Seed Vault file was saved.
  final String savedPath;

  /// Whether this export came from the Settings Backup flow.
  final bool backupWalletFlow;

  @override
  List<Object?> get props => <Object?>[savedPath, backupWalletFlow];
}

/// State emitted when exporting the Seed Vault fails.
final class ExportWalletFailure extends ExportWalletState {
  /// Creates an [ExportWalletFailure] state.
  const ExportWalletFailure({required this.error});

  /// Error encountered while saving the Seed Vault.
  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
