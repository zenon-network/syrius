import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'settings_backup_state.dart';

/// Loads wallet seed metadata for the Settings Backup card.
class SettingsBackupCubit extends Cubit<SettingsBackupState> {
  /// Creates a [SettingsBackupCubit].
  factory SettingsBackupCubit({WalletFile? walletFile}) {
    final WalletFile? resolved = walletFile ?? kWalletFile;
    final bool canBackup = resolved != null && !resolved.isHardwareWallet;
    return SettingsBackupCubit._(walletFile: resolved, canBackup: canBackup);
  }

  SettingsBackupCubit._({required this._walletFile, required bool canBackup})
    : super(SettingsBackupIdle(canBackup: canBackup));

  final WalletFile? _walletFile;

  /// Accesses the keystore mnemonic so the export flow can be started.
  Future<void> requestBackupSeed() async {
    final WalletFile? walletFile = _walletFile;
    if (walletFile == null || walletFile.isHardwareWallet) {
      return;
    }

    emit(SettingsBackupLoading(canBackup: state.canBackup));
    try {
      final String mnemonic = await walletFile.access<String>(
        (Wallet wallet) async => (wallet as KeyStore).mnemonic!,
      );
      if (isClosed) {
        return;
      }
      emit(
        SettingsBackupSeedLoaded(seed: mnemonic, canBackup: state.canBackup),
      );
      emit(SettingsBackupIdle(canBackup: state.canBackup));
    } on Object catch (error, stackTrace) {
      if (isClosed) {
        return;
      }
      addError(error, stackTrace);
      emit(SettingsBackupFailure(error: error, canBackup: state.canBackup));
      emit(SettingsBackupIdle(canBackup: state.canBackup));
    }
  }
}
