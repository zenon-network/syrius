import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reset_wallet/reset_wallet.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_wallet_options/settings_wallet_options.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays cache deletion, wallet reset, and desktop preferences in Settings.
class SettingsWalletOptionsCard extends StatelessWidget {
  /// Creates a [SettingsWalletOptionsCard].
  const SettingsWalletOptionsCard({super.key, this._bloc});

  final SettingsWalletOptionsBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final SettingsWalletOptionsBloc? injected = _bloc;
    if (injected != null) {
      return BlocProvider<SettingsWalletOptionsBloc>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<SettingsWalletOptionsBloc>(
      create: (_) => SettingsWalletOptionsBloc(),
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
      body: BlocBuilder<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
        builder: (BuildContext context, SettingsWalletOptionsState state) {
          return ListView(
            shrinkWrap: true,
            children: <Widget>[
              CustomExpandablePanel(
                context.l10n.deleteCache,
                _buildDeleteCachePanel(context),
              ),
              CustomExpandablePanel(
                context.l10n.resetWallet,
                _buildResetWalletPanel(context),
              ),
              CustomExpandablePanel(
                context.l10n.preferences,
                _buildPreferencesPanel(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.walletOptions,
    description: context.l10n.otherWalletOptions,
  );

  Widget _buildDeleteCachePanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.deleteWalletCacheAndCloseApp,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () {
              // Preserves P2P HTLC Drift swaps and legacy swap boxes via
              // SplashScreen._deleteCache.
              NavigationUtils.pushReplacement(
                context,
                const SplashScreen(deleteCacheFlow: true),
              );
            },
            text: context.l10n.deleteCache,
          ),
        ),
      ],
    );
  }

  Widget _buildResetWalletPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.eraseWalletFilesMakeSureBackup,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () =>
                NavigationUtils.push(context, const ResetWalletScreen()),
            text: context.l10n.resetWallet,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesPanel(
    BuildContext context,
    SettingsWalletOptionsState state,
  ) {
    return Column(
      children: <Widget>[
        _buildLaunchAtStartupRow(context, state.launchAtStartup),
        _buildDesktopNotificationsRow(
          context,
          state.enableDesktopNotifications,
        ),
        _buildClipboardWatcherRow(context, state.enableClipboardWatcher),
        _buildAutoReceiveRow(context, state.autoReceive),
      ],
    );
  }

  Widget _buildLaunchAtStartupRow(BuildContext context, bool value) {
    return Row(
      children: <Widget>[
        Text(
          '${context.l10n.launchAtStartup} ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SyriusCheckbox(
          onChanged: (bool? nextValue) {
            final bool enabled = nextValue ?? false;
            final String status = enabled
                ? context.l10n.enabled
                : context.l10n.disabled;
            context.read<SettingsWalletOptionsBloc>().add(
              SettingsWalletOptionsLaunchAtStartupToggled(
                enabled: enabled,
                notificationTitle: context.l10n.launchAtStartupStatus(status),
                notificationDetails: context.l10n
                    .launchAtStartupPreferenceStatus(status),
                errorTitle: context.l10n.errorSettingLaunchAtStartup,
              ),
            );
          },
          value: value,
          context: context,
        ),
      ],
    );
  }

  Widget _buildDesktopNotificationsRow(BuildContext context, bool value) {
    return Row(
      children: <Widget>[
        Text(
          '${context.l10n.enableDesktopNotifications} ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SyriusCheckbox(
          onChanged: (bool? nextValue) {
            final bool enabled = nextValue ?? false;
            final String status = enabled
                ? context.l10n.enabled
                : context.l10n.disabled;
            context.read<SettingsWalletOptionsBloc>().add(
              SettingsWalletOptionsDesktopNotificationsToggled(
                enabled: enabled,
                notificationTitle: context.l10n.desktopNotificationsStatus(
                  status,
                ),
                notificationDetails: context.l10n
                    .desktopNotificationsPreferenceStatus(status),
                errorTitle: context.l10n.errorSettingDesktopNotifications,
              ),
            );
          },
          value: value,
          context: context,
        ),
      ],
    );
  }

  Widget _buildClipboardWatcherRow(BuildContext context, bool value) {
    return Row(
      children: <Widget>[
        Text(
          context.l10n.enableClipboardWatcher,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SyriusCheckbox(
          onChanged: (bool? nextValue) {
            final bool enabled = nextValue ?? false;
            final String status = enabled
                ? context.l10n.enabled
                : context.l10n.disabled;
            context.read<SettingsWalletOptionsBloc>().add(
              SettingsWalletOptionsClipboardWatcherToggled(
                enabled: enabled,
                notificationTitle: context.l10n.clipboardWatcherStatus(status),
                notificationDetails: context.l10n
                    .clipboardWatcherPreferenceStatus(status),
                errorTitle: context.l10n.errorChangingClipboardWatcher,
              ),
            );
          },
          value: value,
          context: context,
        ),
        StandardTooltipIcon(
          context.l10n.listensClipboardForWalletConnectUri,
          Icons.help,
        ),
      ],
    );
  }

  Widget _buildAutoReceiveRow(BuildContext context, bool value) {
    return Row(
      children: <Widget>[
        Text(
          context.l10n.autoReceiver,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SyriusCheckbox(
          onChanged: (bool? nextValue) {
            final bool enabled = nextValue ?? false;
            final String status = enabled
                ? context.l10n.enabled
                : context.l10n.disabled;
            context.read<SettingsWalletOptionsBloc>().add(
              SettingsWalletOptionsAutoReceiveToggled(
                enabled: enabled,
                notificationTitle: context.l10n.autoReceiverStatus(status),
                notificationDetails: context.l10n.autoReceiverPreferenceStatus(
                  status,
                ),
                errorTitle: context.l10n.errorSettingAutoReceivePreference,
              ),
            );
          },
          value: value,
          context: context,
        ),
        StandardTooltipIcon(
          context.l10n.uncheckToDisableAutoReceiver,
          Icons.help,
        ),
      ],
    );
  }
}
