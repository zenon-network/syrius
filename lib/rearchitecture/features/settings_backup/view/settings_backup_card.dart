import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/dump_mnemonic/dump_mnemonic.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/export_wallet/export_wallet.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_backup/settings_backup.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays encrypted Seed Vault backup and mnemonic dump actions in Settings.
class SettingsBackupCard extends StatelessWidget {
  /// Creates a [SettingsBackupCard].
  const SettingsBackupCard({super.key, this._cubit});

  final SettingsBackupCubit? _cubit;

  @override
  Widget build(BuildContext context) {
    final SettingsBackupCubit? injected = _cubit;
    if (injected != null) {
      return BlocProvider<SettingsBackupCubit>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<SettingsBackupCubit>(
      create: (_) => SettingsBackupCubit(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: BlocConsumer<SettingsBackupCubit, SettingsBackupState>(
        listener: (BuildContext context, SettingsBackupState state) {
          if (state case SettingsBackupSeedLoaded(:final String seed)) {
            NavigationUtils.push(
              context,
              ExportWalletInfoScreen(seed, backupWalletFlow: true),
            );
          } else if (state case SettingsBackupFailure(:final Object error)) {
            unawaited(
              NotificationUtils.sendNotificationError(
                error,
                context.l10n.errorAccessingWalletForBackup,
              ),
            );
          }
        },
        builder: (BuildContext context, SettingsBackupState state) {
          final bool canBackup =
              state.canBackup && state is! SettingsBackupLoading;
          return ListView(
            shrinkWrap: true,
            children: <Widget>[
              CustomExpandablePanel(
                context.l10n.backupWallet,
                _buildBackupWalletButton(context, enabled: canBackup),
              ),
              CustomExpandablePanel(
                context.l10n.dumpMnemonic,
                _buildDumpMnemonicButton(context, enabled: state.canBackup),
              ),
            ],
          );
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.backup,
    description: context.l10n.backupSeedEncryptedOrClearText,
  );

  Widget _buildBackupWalletButton(
    BuildContext context, {
    required bool enabled,
  }) {
    return Center(
      child: SettingsButton(
        onPressed: enabled
            ? () {
                unawaited(
                  context.read<SettingsBackupCubit>().requestBackupSeed(),
                );
              }
            : null,
        text: context.l10n.backupWallet,
      ),
    );
  }

  Widget _buildDumpMnemonicButton(
    BuildContext context, {
    required bool enabled,
  }) {
    return Center(
      child: SettingsButton(
        onPressed: enabled
            ? () {
                NavigationUtils.push(context, const DumpMnemonicScreen());
              }
            : null,
        text: context.l10n.dumpMnemonic,
      ),
    );
  }
}
