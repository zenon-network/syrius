part of 'settings_backup_cubit.dart';

/// Base state for [SettingsBackupCubit].
sealed class SettingsBackupState extends Equatable {
  /// Creates a [SettingsBackupState].
  const SettingsBackupState({required this.canBackup});

  /// Whether the active wallet supports software backup / mnemonic dump.
  final bool canBackup;

  @override
  List<Object?> get props => <Object?>[canBackup];
}

/// Idle state ready for backup actions.
final class SettingsBackupIdle extends SettingsBackupState {
  /// Creates a [SettingsBackupIdle] state.
  const SettingsBackupIdle({required super.canBackup});
}

/// State emitted while reading the wallet seed for export.
final class SettingsBackupLoading extends SettingsBackupState {
  /// Creates a [SettingsBackupLoading] state.
  const SettingsBackupLoading({required super.canBackup});
}

/// State emitted when the wallet mnemonic seed is ready to be exported.
final class SettingsBackupSeedLoaded extends SettingsBackupState {
  /// Creates a [SettingsBackupSeedLoaded] state.
  const SettingsBackupSeedLoaded({
    required this.seed,
    required super.canBackup,
  });

  /// Mnemonic seed string loaded from the wallet keystore.
  final String seed;

  @override
  List<Object?> get props => <Object?>[seed, canBackup];
}

/// State emitted when accessing the wallet seed fails.
final class SettingsBackupFailure extends SettingsBackupState {
  /// Creates a [SettingsBackupFailure] state.
  const SettingsBackupFailure({required this.error, required super.canBackup});

  /// Error encountered while reading the wallet seed.
  final Object error;

  @override
  List<Object?> get props => <Object?>[error, canBackup];
}
