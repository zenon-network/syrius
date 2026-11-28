import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/metadata.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'settings_sections.dart';

/// Redesigned split-pane Settings screen matching mockups Screens 30–38.
class SettingsTabChild extends StatelessWidget {
  /// Creates a [SettingsTabChild].
  const SettingsTabChild(
    this._onChangeAutoLockTime, {
    required this._onStepperNotificationSeeMorePressed,
    required this._onNodeChangedCallback,
    super.key,
  });

  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback _onNodeChangedCallback;

  @override
  Widget build(BuildContext context) {
    final bool hasWeb3 = sl.isRegistered<IWeb3WalletService>();
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<AccountChainStatsBloc>(
          create: (_) {
            final AccountChainStatsBloc bloc = AccountChainStatsBloc(
              zenon: zenon!,
              wsRestartedStream: zenon!.wsClient.restartedStream,
            );
            final String? selectedAddress = kSelectedAddress;
            if (selectedAddress != null) {
              bloc.add(
                FetchRequestData(address: Address.parse(selectedAddress)),
              );
            }
            return bloc;
          },
        ),
        BlocProvider<SettingsAddressesBloc>(
          create: (_) => SettingsAddressesBloc(),
        ),
        BlocProvider<NodeManagementBloc>(
          create: (_) => NodeManagementBloc(
            checkChainIdMismatch: true,
            resetHtlcBlockHeightOnChange: true,
          )..add(const NodeManagementChainIdLoaded()),
        ),
        BlocProvider<SettingsSecurityBloc>(
          create: (_) => SettingsSecurityBloc(),
        ),
        BlocProvider<SettingsDisplayCubit>(
          create: (_) => SettingsDisplayCubit(),
        ),
        BlocProvider<SettingsWalletOptionsBloc>(
          create: (_) => SettingsWalletOptionsBloc(),
        ),
        BlocProvider<SettingsBackupCubit>(create: (_) => SettingsBackupCubit()),
        BlocProvider<PeersBloc>(
          create: (_) => PeersBloc(
            zenon: zenon!,
            wsRestartedStream: zenon!.wsClient.restartedStream,
          )..add(const PeersRequested()),
        ),
        BlocProvider<AboutBloc>(
          create: (_) => AboutBloc(zenon: zenon!)..add(const AboutRequested()),
        ),
        if (hasWeb3) ...<SingleChildWidget>[
          BlocProvider<WalletConnectSessionsBloc>(
            create: (_) => WalletConnectSessionsBloc(
              web3WalletService: sl<IWeb3WalletService>(),
            ),
          ),
          BlocProvider<WalletConnectPairingsBloc>(
            create: (_) => WalletConnectPairingsBloc(
              web3WalletService: sl<IWeb3WalletService>(),
            ),
          ),
          BlocProvider<WalletConnectPairBloc>(
            create: (_) => WalletConnectPairBloc(
              web3WalletService: sl<IWeb3WalletService>(),
            ),
          ),
        ],
      ],
      child: _SettingsWorkspaceView(
        onChangeAutoLockTime: _onChangeAutoLockTime,
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
        onNodeChangedCallback: _onNodeChangedCallback,
        hasWeb3: hasWeb3,
      ),
    );
  }
}

class _SettingsWorkspaceView extends StatefulWidget {
  const _SettingsWorkspaceView({
    required this.onChangeAutoLockTime,
    required this.onStepperNotificationSeeMorePressed,
    required this.onNodeChangedCallback,
    required this.hasWeb3,
  });

  final VoidCallback onChangeAutoLockTime;
  final VoidCallback onStepperNotificationSeeMorePressed;
  final VoidCallback onNodeChangedCallback;
  final bool hasWeb3;

  @override
  State<_SettingsWorkspaceView> createState() => _SettingsWorkspaceViewState();
}

class _SettingsWorkspaceViewState extends State<_SettingsWorkspaceView> {
  ShellNavigationController? _nav;
  SettingsSection _section = SettingsSection.addresses;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ShellNavigationController? nav =
        Provider.of<ShellNavigationController?>(context, listen: false);
    if (!identical(nav, _nav)) {
      _nav?.settingsSection.removeListener(_onNavSectionChanged);
      _nav = nav;
      if (_nav != null) {
        _section = _nav!.settingsSection.value;
        _nav!.settingsSection.addListener(_onNavSectionChanged);
      }
    }
  }

  void _onNavSectionChanged() {
    final SettingsSection next = _nav!.settingsSection.value;
    if (next != _section && mounted) {
      setState(() => _section = next);
    }
  }

  void _selectSection(SettingsSection section) {
    setState(() => _section = section);
    _nav?.requestSettingsSection(section);
  }

  @override
  void dispose() {
    _nav?.settingsSection.removeListener(_onNavSectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: 196,
          child: SyriusCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildNavItem(
                  tokens,
                  section: SettingsSection.addresses,
                  icon: Icons.bookmark_border_rounded,
                  label: context.l10n.addresses,
                ),
                _buildNavItem(
                  tokens,
                  section: SettingsSection.node,
                  icon: Icons.language_rounded,
                  label: context.l10n.node,
                ),
                _buildNavItem(
                  tokens,
                  section: SettingsSection.security,
                  icon: Icons.shield_outlined,
                  label: context.l10n.security,
                ),
                _buildNavItem(
                  tokens,
                  section: SettingsSection.display,
                  icon: Icons.visibility_outlined,
                  label: context.l10n.display,
                ),
                _buildNavItem(
                  tokens,
                  section: SettingsSection.wallet,
                  icon: Icons.wb_sunny_outlined,
                  label: context.l10n.wallet,
                ),
                _buildNavItem(
                  tokens,
                  section: SettingsSection.apps,
                  icon: Icons.link_rounded,
                  label: context.l10n.apps,
                ),
                _buildNavItem(
                  tokens,
                  section: SettingsSection.about,
                  icon: Icons.info_outline_rounded,
                  label: context.l10n.about,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: switch (_section) {
              SettingsSection.addresses => const _AddressesSettingsPane(),
              SettingsSection.node => _NodeSettingsPane(
                onNodeChangedCallback: widget.onNodeChangedCallback,
              ),
              SettingsSection.security => _SecuritySettingsPane(
                onChangeAutoLockTime: widget.onChangeAutoLockTime,
                onStepperNotificationSeeMorePressed:
                    widget.onStepperNotificationSeeMorePressed,
              ),
              SettingsSection.display => const _DisplaySettingsPane(),
              SettingsSection.wallet => const _WalletSettingsPane(),
              SettingsSection.apps => _AppsSettingsPane(
                hasWeb3: widget.hasWeb3,
              ),
              SettingsSection.about => const _AboutSettingsPane(),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    SyriusThemeTokens tokens, {
    required SettingsSection section,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _section == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _selectSection(section),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? tokens.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: selected ? tokens.znnGreen : tokens.textMuted,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
