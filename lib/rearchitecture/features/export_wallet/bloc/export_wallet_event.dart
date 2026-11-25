part of 'export_wallet_bloc.dart';

/// Base class for [ExportWalletBloc] events.
sealed class ExportWalletEvent extends Equatable {
  /// Creates an [ExportWalletEvent].
  const ExportWalletEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests exporting an encrypted Seed Vault JSON file for [seed] encrypted
/// with [password].
final class ExportWalletRequested extends ExportWalletEvent {
  /// Creates an [ExportWalletRequested] event.
  const ExportWalletRequested({
    required this.seed,
    required this.password,
    required this.backupWalletFlow,
    required this.successTitle,
    required this.successDetailsBuilder,
    required this.errorTitle,
  });

  /// Mnemonic seed string to encrypt.
  final String seed;

  /// Password used to encrypt the Seed Vault file.
  final String password;

  /// Whether triggered from Settings Backup (sends notification) vs onboarding
  /// (updates exported seeds notifier).
  final bool backupWalletFlow;

  /// Localized notification title on successful backup export.
  final String successTitle;

  /// Builds localized notification details given the saved file path.
  final String Function(String savedPath) successDetailsBuilder;

  /// Localized error notification title if exporting fails.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    seed,
    password,
    backupWalletFlow,
    successTitle,
    errorTitle,
  ];
}
