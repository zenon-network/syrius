part of 'settings_tab_child.dart';

/// Shared collapsible card section used across Settings panes.
class _SettingsCollapsibleCard extends StatefulWidget {
  const _SettingsCollapsibleCard({
    required this.title,
    required this.child,
    this.count,
    this.trailingSummary,
  });

  final String title;
  final int? count;
  final String? trailingSummary;
  final Widget child;

  @override
  State<_SettingsCollapsibleCard> createState() =>
      _SettingsCollapsibleCardState();
}

class _SettingsCollapsibleCardState extends State<_SettingsCollapsibleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return SyriusCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: <Widget>[
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  if (widget.count != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(
                      '${widget.count}',
                      style: tokens.monoStyle(
                        fontSize: 12.5,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.trailingSummary != null) ...<Widget>[
                    Text(
                      widget.trailingSummary!,
                      style: TextStyle(fontSize: 12.5, color: tokens.textMuted),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: tokens.textMuted,
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _expanded,
            maintainState: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Divider(height: 1, color: tokens.border),
                Padding(padding: const EdgeInsets.all(18), child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: tokens.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

// =============================================================================
// 1. ADDRESSES (Screen 35)
// =============================================================================

class _AddressesSettingsPane extends StatelessWidget {
  const _AddressesSettingsPane();

  void _onDefaultAddressChanged(
    BuildContext context,
    SettingsAddressesState state,
  ) {
    final String? next = state.selectedAddress;
    if (next == null) {
      return;
    }
    Provider.of<SelectedAddressNotifier>(
      context,
      listen: false,
    ).changeSelectedAddress(next);
    context.read<PlasmaBeneficiaryAddressCubit>().changeAddress(next);
    final Address parsed = Address.parse(next);
    context.read<AccountChainStatsBloc>().add(
      FetchRequestData(address: parsed),
    );
    context.read<LatestTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: parsed),
    );
    context.read<PendingTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: parsed),
    );
    context.read<PillarRewardsHistoryBloc>().add(
      FetchRequestData(address: parsed),
    );
    context.read<SentinelRewardsHistoryBloc>().add(
      FetchRequestData(address: parsed),
    );
    context.read<StakingRewardsHistoryBloc>().add(
      FetchRequestData(address: parsed),
    );
    context.read<PillarsByOwnerBloc>().add(FetchRequestData(address: parsed));
    context.read<DelegationStatsBloc>().add(FetchRequestData(address: parsed));
  }

  Future<void> _showEditLabelDialog(
    BuildContext context, {
    required String address,
    required String currentLabel,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: currentLabel,
    );
    final SettingsAddressesBloc bloc = context.read<SettingsAddressesBloc>();
    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 400,
      builder: (BuildContext dialogContext) {
        return SyriusModalShell(
          title: context.l10n.edit,
          actions: <Widget>[
            SyriusPillButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            SyriusGradientButton(
              label: context.l10n.confirm,
              height: 36,
              onPressed: () {
                bloc.add(
                  SettingsAddressesLabelUpdated(
                    address: address,
                    label: controller.text.trim(),
                  ),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: context.l10n.addressLabel),
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showAddContactDialog(
    BuildContext context, {
    String? initialAddress,
    String? initialName,
  }) async {
    final TextEditingController nameCtrl = TextEditingController(
      text: initialName ?? '',
    );
    final TextEditingController addrCtrl = TextEditingController(
      text: initialAddress ?? '',
    );
    final AppUiPreferencesNotifier prefs = context
        .read<AppUiPreferencesNotifier>();

    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 440,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final String addr = addrCtrl.text.trim();
            final String name = nameCtrl.text.trim();
            final String? addrError = addr.isEmpty
                ? null
                : InputValidators.checkAddress(addr, l10n: context.l10n);
            final bool canSave =
                addr.isNotEmpty && name.isNotEmpty && addrError == null;

            return SyriusModalShell(
              title: context.l10n.addContact,
              actions: <Widget>[
                SyriusPillButton(
                  label: context.l10n.cancel,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                SyriusGradientButton(
                  label: context.l10n.confirm,
                  height: 36,
                  onPressed: canSave
                      ? () {
                          if (initialAddress != null &&
                              initialAddress != addr) {
                            prefs.removeContact(initialAddress);
                          }
                          prefs.saveContact(addr, name);
                          Navigator.of(dialogContext).pop();
                        }
                      : null,
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameCtrl,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(hintText: context.l10n.name),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addrCtrl,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: context.l10n.p2pSwapAddressHint,
                      errorText: addrError,
                      suffixIcon: PasteContentButton(
                        controller: addrCtrl,
                        onPasted: (_) => setModalState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameCtrl.dispose();
    addrCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();
    final Map<String, String> contacts = uiPrefs.contacts;

    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        BlocListener<SettingsAddressesBloc, SettingsAddressesState>(
          listenWhen:
              (SettingsAddressesState prev, SettingsAddressesState curr) =>
                  prev.defaultAddressChangeNonce !=
                  curr.defaultAddressChangeNonce,
          listener: _onDefaultAddressChanged,
        ),
        BlocListener<SettingsAddressesBloc, SettingsAddressesState>(
          listenWhen:
              (SettingsAddressesState prev, SettingsAddressesState curr) =>
                  prev.generateErrorNonce != curr.generateErrorNonce &&
                  curr.generateError != null,
          listener: (BuildContext context, SettingsAddressesState state) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.generateError!,
                context.l10n.errorWhileGeneratingNewAddress,
              ),
            );
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlocBuilder<SettingsAddressesBloc, SettingsAddressesState>(
            builder: (BuildContext context, SettingsAddressesState state) {
              return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
                builder: (_, MultipleBalanceState balState) {
                  final Map<String, AccountInfo> balances =
                      balState.data ?? const <String, AccountInfo>{};
                  return SyriusCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                          child: Row(
                            children: <Widget>[
                              Text(
                                context.l10n.yourAddresses,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${state.addresses.length}',
                                style: tokens.monoStyle(
                                  fontSize: 12.5,
                                  color: tokens.textMuted,
                                ),
                              ),
                              const Spacer(),
                              SyriusPillButton(
                                label: context.l10n.addAddress,
                                icon: Icons.add,
                                compact: true,
                                onPressed: () {
                                  context.read<SettingsAddressesBloc>().add(
                                    const SettingsAddressesGenerateRequested(
                                      count: 1,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: tokens.border),
                        if (state.status == SettingsAddressesStatus.loading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: SyriusLoadingWidget(),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.addresses.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: tokens.border),
                            itemBuilder: (BuildContext context, int index) {
                              final String addr = state.addresses[index];
                              final bool selected =
                                  addr == state.selectedAddress;
                              final String label =
                                  state.addressLabels[addr] ??
                                  context.l10n.addressNumber(index + 1);
                              final AccountInfo? info = balances[addr];
                              final String znnVal = uiPrefs.hideBalances
                                  ? '••••'
                                  : (info?.getBalance(kZnnCoin.tokenStandard) ??
                                            BigInt.zero)
                                        .addDecimals(coinDecimals);
                              final String qsrVal = uiPrefs.hideBalances
                                  ? '••••'
                                  : (info?.getBalance(kQsrCoin.tokenStandard) ??
                                            BigInt.zero)
                                        .addDecimals(coinDecimals);

                              return InkWell(
                                onTap: () {
                                  context.read<SettingsAddressesBloc>().add(
                                    SettingsAddressesDefaultChanged(
                                      address: addr,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 3,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? tokens.znnGreen
                                              : tokens.borderStrong,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: tokens.textPrimary,
                                                  ),
                                                ),
                                                if (selected) ...<Widget>[
                                                  const SizedBox(width: 8),
                                                  SyriusStatusBadge(
                                                    label:
                                                        context.l10n.selected,
                                                    tone:
                                                        SyriusBadgeTone.success,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              addr,
                                              overflow: TextOverflow.ellipsis,
                                              style: tokens.monoStyle(
                                                fontSize: 11.5,
                                                color: tokens.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          '$znnVal ${kZnnCoin.symbol}',
                                          textAlign: TextAlign.right,
                                          style: tokens.monoStyle(
                                            fontWeight: FontWeight.w500,
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          '$qsrVal ${kQsrCoin.symbol}',
                                          textAlign: TextAlign.right,
                                          style: tokens.monoStyle(
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        tooltip: context.l10n.edit,
                                        iconSize: 15,
                                        splashRadius: 16,
                                        color: tokens.textMuted,
                                        onPressed: () => unawaited(
                                          _showEditLabelDialog(
                                            context,
                                            address: addr,
                                            currentLabel: label,
                                          ),
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: context.l10n.copyAddress,
                                        iconSize: 15,
                                        splashRadius: 16,
                                        color: tokens.textMuted,
                                        onPressed: () =>
                                            ClipboardUtils.copyToClipboard(
                                              addr,
                                              context,
                                            ),
                                        icon: const Icon(Icons.copy_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          SyriusCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Row(
                    children: <Widget>[
                      Text(
                        context.l10n.contacts,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${contacts.length}',
                        style: tokens.monoStyle(
                          fontSize: 12.5,
                          color: tokens.textMuted,
                        ),
                      ),
                      const Spacer(),
                      SyriusPillButton(
                        label: context.l10n.addContact,
                        icon: Icons.add,
                        compact: true,
                        onPressed: () =>
                            unawaited(_showAddContactDialog(context)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: tokens.border),
                if (contacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      context.l10n.noneYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: tokens.textMuted),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: tokens.border),
                    itemBuilder: (BuildContext context, int index) {
                      final MapEntry<String, String> entry = contacts.entries
                          .elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 140,
                              child: Text(
                                entry.value,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.key,
                                overflow: TextOverflow.ellipsis,
                                style: tokens.monoStyle(
                                  fontSize: 12,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SyriusPillButton(
                              label: context.l10n.send,
                              compact: true,
                              height: 28,
                              onPressed: () {
                                Provider.of<ShellNavigationController?>(
                                  context,
                                  listen: false,
                                )?.requestTransfer(
                                  mode: TransferMode.send,
                                  recipientAddress: entry.key,
                                );
                              },
                            ),
                            IconButton(
                              tooltip: context.l10n.edit,
                              iconSize: 15,
                              splashRadius: 16,
                              color: tokens.textMuted,
                              onPressed: () => unawaited(
                                _showAddContactDialog(
                                  context,
                                  initialAddress: entry.key,
                                  initialName: entry.value,
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: context.l10n.delete,
                              iconSize: 15,
                              splashRadius: 16,
                              color: tokens.textMuted,
                              onPressed: () => uiPrefs.removeContact(entry.key),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<AccountChainStatsBloc, FetchState<AccountChainStats>>(
            builder:
                (
                  BuildContext context,
                  FetchState<AccountChainStats> statsState,
                ) {
                  final String selectedLabel =
                      kAddressLabelMap[kSelectedAddress] ??
                      context.l10n.addressNumber(1);
                  final String summary =
                      statsState is FetchPopulated<AccountChainStats>
                      ? '${statsState.data.blockCount} blocks'
                      : '';
                  return _SettingsCollapsibleCard(
                    title: 'Account chain of $selectedLabel',
                    trailingSummary: summary,
                    child: switch (statsState) {
                      FetchInitial<AccountChainStats>() =>
                        const SyriusLoadingWidget(),
                      FetchFailure<AccountChainStats>(
                        :final SyriusException exception,
                      ) =>
                        SyriusErrorWidget(
                          exception is EmptyAccountChainException
                              ? context.l10n.emptyAccountChain
                              : exception,
                        ),
                      FetchPopulated<AccountChainStats>(
                        :final AccountChainStats data,
                      ) =>
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SyriusKeyValueRow(
                              label: context.l10n.accountChainHeight,
                              labelWidth: 160,
                              value: Text(
                                '${data.blockCount}',
                                style: tokens.monoStyle(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            SyriusKeyValueRow(
                              label: context.l10n.blockHash,
                              labelWidth: 160,
                              value: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      data.firstHash.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: tokens.monoStyle(
                                        fontSize: 12,
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ),
                                  CopyToClipboardButton(
                                    data.firstHash.toString(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    },
                  );
                },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. NODE (Screen 30)
// =============================================================================

class _NodeSettingsPane extends StatefulWidget {
  const _NodeSettingsPane({required this.onNodeChangedCallback});

  final VoidCallback onNodeChangedCallback;

  @override
  State<_NodeSettingsPane> createState() => _NodeSettingsPaneState();
}

class _NodeSettingsPaneState extends State<_NodeSettingsPane> {
  static final NumberFormat _intFormat = NumberFormat.decimalPattern();
  final TextEditingController _chainIdController = TextEditingController();

  @override
  void dispose() {
    _chainIdController.dispose();
    super.dispose();
  }

  Future<void> _showAddNodeDialog(BuildContext context) async {
    final TextEditingController nodeCtrl = TextEditingController();
    final NodeManagementBloc bloc = context.read<NodeManagementBloc>();
    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 420,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final String? err = InputValidators.node(
              nodeCtrl.text,
              l10n: context.l10n,
            );
            final bool valid = nodeCtrl.text.isNotEmpty && err == null;
            return SyriusModalShell(
              title: context.l10n.addNode,
              actions: <Widget>[
                SyriusPillButton(
                  label: context.l10n.cancel,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                SyriusGradientButton(
                  label: context.l10n.addNode,
                  height: 36,
                  onPressed: valid
                      ? () {
                          final String node = nodeCtrl.text.trim();
                          bloc.add(
                            NodeManagementAddNodeRequested(
                              node: node,
                              duplicateDetails: context.l10n
                                  .nodeAlreadyExistsNamed(node),
                              duplicateTitle: context.l10n.nodeAlreadyExists,
                              successTitle: context.l10n.successfullyAddedNode(
                                node,
                              ),
                              successDetails: context.l10n
                                  .successfullyAddedNode(node),
                              errorTitle: context.l10n.errorAddingNewNode,
                            ),
                          );
                          Navigator.of(dialogContext).pop();
                        }
                      : null,
                ),
              ],
              child: TextField(
                controller: nodeCtrl,
                autofocus: true,
                onChanged: (_) => setModalState(() {}),
                decoration: InputDecoration(
                  hintText: context.l10n.nodeAddressWithPort,
                  errorText: nodeCtrl.text.isEmpty ? null : err,
                ),
              ),
            );
          },
        );
      },
    );
    nodeCtrl.dispose();
  }

  Future<void> _showChainIdMismatchDialog(
    BuildContext context,
    NodeChainIdMismatchPrompt prompt,
  ) async {
    final bool proceed = await showWarningDialog(
      context: context,
      title: context.l10n.chainIdentifierMismatch,
      buttonText: context.l10n.proceedAnyway,
      description: context.l10n.nodeHasDifferentChainIdentifier(
        prompt.node,
        prompt.nodeChainId,
        prompt.clientChainId,
      ),
    );
    if (!context.mounted) {
      return;
    }
    context.read<NodeManagementBloc>().add(
      NodeManagementChainIdMismatchResolved(
        proceed: proceed,
        connectionFailedTitle: context.l10n.connectionFailed,
        connectionUnavailableMessage: context.l10n
            .connectionCouldNotBeEstablished(
              proceed ? prompt.node : prompt.previousNode,
            ),
      ),
    );
  }

  void _connectNode(
    BuildContext context,
    NodeManagementBloc bloc,
    String node,
  ) {
    bloc
      ..add(NodeManagementNodeSelected(node: node))
      ..add(
        NodeManagementConfirmNodeRequested(
          successTitle: context.l10n.successfullyConnectedToNode(node),
          successDetails: context.l10n.successfullyConnectedToNode(node),
          connectionUnavailableMessage: context.l10n
              .connectionCouldNotBeEstablished(node),
          connectionFailedTitle: context.l10n.connectionFailed,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        BlocListener<NodeManagementBloc, NodeManagementState>(
          listenWhen: (NodeManagementState prev, NodeManagementState curr) =>
              prev.nodeConfirmedNonce != curr.nodeConfirmedNonce,
          listener: (_, _) => widget.onNodeChangedCallback(),
        ),
        BlocListener<NodeManagementBloc, NodeManagementState>(
          listenWhen: (NodeManagementState prev, NodeManagementState curr) =>
              prev.pendingChainIdMismatch != curr.pendingChainIdMismatch &&
              curr.pendingChainIdMismatch != null &&
              !curr.pendingChainIdMismatch!.reconnectFailed,
          listener: (BuildContext context, NodeManagementState state) {
            unawaited(
              _showChainIdMismatchDialog(
                context,
                state.pendingChainIdMismatch!,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<NodeManagementBloc, NodeManagementState>(
        builder: (BuildContext context, NodeManagementState nodeState) {
          final NodeManagementBloc bloc = context.read<NodeManagementBloc>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SyriusCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                      child: Row(
                        children: <Widget>[
                          Text(
                            context.l10n.nodes,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${nodeState.nodes.length}',
                            style: tokens.monoStyle(
                              fontSize: 12.5,
                              color: tokens.textMuted,
                            ),
                          ),
                          const Spacer(),
                          BlocBuilder<NodeSyncStatusCubit, NodeSyncStatusState>(
                            builder: (_, NodeSyncStatusState sync) {
                              final int height =
                                  sync.data?.second.currentHeight ?? 0;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: height > 0
                                          ? tokens.znnGreen
                                          : tokens.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Momentum ${_intFormat.format(height)}  '
                                    'Chain ${nodeState.clientChainId}',
                                    style: tokens.monoStyle(
                                      fontSize: 11.5,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          SyriusPillButton(
                            label: context.l10n.addNode,
                            icon: Icons.add,
                            compact: true,
                            onPressed: () =>
                                unawaited(_showAddNodeDialog(context)),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: tokens.border),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: nodeState.nodes.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: tokens.border),
                      itemBuilder: (BuildContext context, int index) {
                        final String node = nodeState.nodes[index];
                        final bool isConfirmed =
                            node == nodeState.confirmedNode;
                        final bool isCustom =
                            !bloc.isDefaultNode(node) &&
                            !bloc.isCommunityNode(node);
                        final String displayTitle = node == kEmbeddedNode
                            ? context.l10n.embeddedNode
                            : node;
                        final String subtitleUrl = node == kEmbeddedNode
                            ? kLocalhostDefaultNodeUrl
                            : node;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 3,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? tokens.znnGreen
                                      : tokens.borderStrong,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      displayTitle,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleUrl,
                                      overflow: TextOverflow.ellipsis,
                                      style: tokens.monoStyle(
                                        fontSize: 11.5,
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Chain ${nodeState.clientChainId}',
                                style: tokens.monoStyle(
                                  fontSize: 12,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (isConfirmed)
                                SyriusStatusBadge(
                                  label: context.l10n.connected,
                                  tone: SyriusBadgeTone.success,
                                  icon: Icons.check,
                                )
                              else
                                SyriusPillButton(
                                  label: context.l10n.connect,
                                  compact: true,
                                  height: 28,
                                  isLoading:
                                      nodeState.isConfirmingNode &&
                                      nodeState.selectedNode == node,
                                  onPressed: nodeState.isConfirmingNode
                                      ? null
                                      : () => _connectNode(context, bloc, node),
                                ),
                              if (isCustom) ...<Widget>[
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: context.l10n.delete,
                                  iconSize: 15,
                                  splashRadius: 16,
                                  color: tokens.textMuted,
                                  onPressed: () {
                                    bloc.add(
                                      NodeManagementDeleteNodeRequested(
                                        node: node,
                                        errorTitle: context.l10n
                                            .errorDeletingNodeFromDatabase(
                                              node,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<AboutBloc, AboutState>(
                builder: (_, AboutState aboutState) {
                  final String nodeVer = aboutState is AboutPopulated
                      ? (aboutState.nodeInfo.processInfo?.version ?? 'bundled')
                      : 'bundled';
                  final String dataPath = znnDefaultPaths.main.absolute.path;
                  return SyriusCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          context.l10n.embeddedNode,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SyriusKeyValueRow(
                          label: 'Running',
                          labelWidth: 96,
                          value: Text(
                            nodeVer,
                            style: tokens.monoStyle(
                              fontSize: 12.5,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        SyriusKeyValueRow(
                          label: 'Data',
                          labelWidth: 96,
                          value: InkWell(
                            onTap: () => unawaited(OpenFilex.open(dataPath)),
                            child: Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    dataPath,
                                    overflow: TextOverflow.ellipsis,
                                    style: tokens.monoStyle(
                                      fontSize: 12,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.open_in_new,
                                  size: 13,
                                  color: tokens.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _SettingsCollapsibleCard(
                title: context.l10n.chainIdentifier,
                trailingSummary: '${nodeState.clientChainId}',
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _chainIdController,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '${nodeState.clientChainId}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SyriusPillButton(
                      label: context.l10n.confirm,
                      isLoading: nodeState.isConfirmingChainId,
                      onPressed: () {
                        final int? nextId = int.tryParse(
                          _chainIdController.text.trim(),
                        );
                        if (nextId == null ||
                            nextId == nodeState.clientChainId) {
                          return;
                        }
                        bloc.add(
                          NodeManagementChainIdChanged(
                            newChainId: nextId,
                            successTitle: context.l10n
                                .changedClientChainIdentifier(nextId),
                            successDetails: context.l10n
                                .changedClientChainIdentifierFromTo(
                                  nodeState.clientChainId,
                                  nextId,
                                ),
                            errorTitle:
                                context.l10n.errorSettingClientChainIdentifier,
                          ),
                        );
                        _chainIdController.clear();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<PeersBloc, PeersState>(
                builder: (_, PeersState peersState) {
                  final List<Peer> peers = peersState is PeersPopulated
                      ? peersState.peers
                      : const <Peer>[];
                  return _SettingsCollapsibleCard(
                    title: context.l10n.peers,
                    count: peers.length,
                    child: peers.isEmpty
                        ? Text(
                            context.l10n.noPeersFound,
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.textMuted,
                            ),
                          )
                        : Column(
                            children: peers
                                .map(
                                  (Peer peer) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            peer.ip,
                                            style: tokens.monoStyle(
                                              fontSize: 12,
                                              color: tokens.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            peer.publicKey,
                                            overflow: TextOverflow.ellipsis,
                                            style: tokens.monoStyle(
                                              fontSize: 11.5,
                                              color: tokens.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsCollapsibleCard(
                title: context.l10n.sporks,
                trailingSummary: uiPrefs.sporksMode.name,
                child: Row(
                  children: <Widget>[
                    Text(
                      context.l10n.modes,
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    SyriusSegmentedControl<FeatureDisplayMode>(
                      selected: uiPrefs.sporksMode,
                      onChanged: uiPrefs.setSporksMode,
                      options: <SyriusSegmentOption<FeatureDisplayMode>>[
                        SyriusSegmentOption<FeatureDisplayMode>(
                          value: FeatureDisplayMode.auto,
                          label: context.l10n.autoLabel,
                        ),
                        SyriusSegmentOption<FeatureDisplayMode>(
                          value: FeatureDisplayMode.on,
                          label: context.l10n.onLabel,
                        ),
                        SyriusSegmentOption<FeatureDisplayMode>(
                          value: FeatureDisplayMode.off,
                          label: context.l10n.off,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// 3. SECURITY (Screen 31)
// =============================================================================

class _SecuritySettingsPane extends StatefulWidget {
  const _SecuritySettingsPane({
    required this.onChangeAutoLockTime,
    required this.onStepperNotificationSeeMorePressed,
  });

  final VoidCallback onChangeAutoLockTime;
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<_SecuritySettingsPane> createState() => _SecuritySettingsPaneState();
}

class _SecuritySettingsPaneState extends State<_SecuritySettingsPane> {
  final TextEditingController _signMsgController = TextEditingController();
  final TextEditingController _verifyMsgController = TextEditingController();
  final TextEditingController _verifySigController = TextEditingController();
  final TextEditingController _verifyPubKeyController = TextEditingController();
  final TextEditingController _verifyFileHashController =
      TextEditingController();
  final TextEditingController _verifyFilePubKeyController =
      TextEditingController();
  final GlobalKey<SelectFileWidgetState> _signFileKey =
      GlobalKey<SelectFileWidgetState>();
  final GlobalKey<SelectFileWidgetState> _verifyFileKey =
      GlobalKey<SelectFileWidgetState>();
  String? _signFilePath;
  String? _verifyFilePath;

  @override
  void dispose() {
    _signMsgController.dispose();
    _verifyMsgController.dispose();
    _verifySigController.dispose();
    _verifyPubKeyController.dispose();
    _verifyFileHashController.dispose();
    _verifyFilePubKeyController.dispose();
    super.dispose();
  }

  int _nearestLockPreset(int minutes) {
    if (minutes <= 0) {
      return 0;
    }
    if (minutes <= 7) {
      return 5;
    }
    if (minutes <= 30) {
      return 15;
    }
    return 60;
  }

  int _nearestErasePreset(double attempts) {
    final int rounded = attempts.round();
    if (rounded <= 0) {
      return 0;
    }
    if (rounded <= 4) {
      return 3;
    }
    if (rounded <= 7) {
      return 5;
    }
    return 10;
  }

  Widget _buildPasteField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: PasteContentButton(
          controller: controller,
          onPasted: (_) {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
          listenWhen:
              (SettingsSecurityState prev, SettingsSecurityState curr) =>
                  prev.autoLockConfirmedNonce != curr.autoLockConfirmedNonce,
          listener: (_, _) => widget.onChangeAutoLockTime(),
        ),
        BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
          listenWhen:
              (SettingsSecurityState prev, SettingsSecurityState curr) =>
                  prev.messageVerifiedNonce != curr.messageVerifiedNonce,
          listener: (_, _) {
            setState(() {
              _verifyMsgController.clear();
              _verifySigController.clear();
              _verifyPubKeyController.clear();
            });
          },
        ),
        BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
          listenWhen:
              (SettingsSecurityState prev, SettingsSecurityState curr) =>
                  prev.fileSignedNonce != curr.fileSignedNonce,
          listener: (_, _) {
            setState(() {
              _signFilePath = null;
              _signFileKey.currentState?.resetMessageToUser();
            });
          },
        ),
        BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
          listenWhen:
              (SettingsSecurityState prev, SettingsSecurityState curr) =>
                  prev.fileVerifiedNonce != curr.fileVerifiedNonce,
          listener: (_, _) {
            setState(() {
              _verifyFilePath = null;
              _verifyFileKey.currentState?.resetMessageToUser();
              _verifyFileHashController.clear();
              _verifyFilePubKeyController.clear();
            });
          },
        ),
        BlocListener<SettingsBackupCubit, SettingsBackupState>(
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
        ),
      ],
      child: BlocBuilder<SettingsSecurityBloc, SettingsSecurityState>(
        builder: (BuildContext context, SettingsSecurityState state) {
          final SettingsSecurityBloc secBloc = context
              .read<SettingsSecurityBloc>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SyriusCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    _SettingsRow(
                      title: context.l10n.lockAfter,
                      subtitle: state.autoLockMinutes <= 0
                          ? context.l10n.onClose
                          : context.l10n.lockAfterMinutesOfInactivity(
                              state.autoLockMinutes,
                            ),
                      trailing: SyriusSegmentedControl<int>(
                        selected: _nearestLockPreset(state.autoLockMinutes),
                        enabled: !state.isConfirmingAutoLock,
                        onChanged: (int minutes) {
                          secBloc
                            ..add(
                              SettingsSecurityAutoLockChanged(minutes: minutes),
                            )
                            ..add(
                              SettingsSecurityAutoLockConfirmed(
                                errorTitle: context
                                    .l10n
                                    .errorConfirmingAutoLockInterval,
                              ),
                            );
                        },
                        options: <SyriusSegmentOption<int>>[
                          const SyriusSegmentOption<int>(
                            value: 5,
                            label: '5 min',
                          ),
                          const SyriusSegmentOption<int>(
                            value: 15,
                            label: '15 min',
                          ),
                          const SyriusSegmentOption<int>(
                            value: 60,
                            label: '1 h',
                          ),
                          SyriusSegmentOption<int>(
                            value: 0,
                            label: context.l10n.onClose,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: tokens.border),
                    _SettingsRow(
                      title: context.l10n.removeWalletAfterWrongPasswords,
                      subtitle: state.autoEraseAttempts <= 0
                          ? context.l10n.off
                          : context.l10n.eraseAfterFailedPasswordAttempts(
                              state.autoEraseAttempts.toInt(),
                            ),
                      trailing: SyriusSegmentedControl<int>(
                        selected: _nearestErasePreset(state.autoEraseAttempts),
                        enabled: !state.isConfirmingAutoErase,
                        onChanged: (int attempts) {
                          final double val = attempts.toDouble();
                          secBloc
                            ..add(
                              SettingsSecurityAutoEraseChanged(attempts: val),
                            )
                            ..add(
                              SettingsSecurityAutoEraseConfirmed(
                                notificationTitle:
                                    context.l10n.autoEraseLimitChanged,
                                notificationDetails: attempts == 0
                                    ? context.l10n.off
                                    : context.l10n.autoEraseLimitNowAttempts(
                                        attempts.toString(),
                                      ),
                                errorTitle:
                                    context.l10n.errorConfirmingAutoEraseLimit,
                              ),
                            );
                        },
                        options: <SyriusSegmentOption<int>>[
                          SyriusSegmentOption<int>(
                            value: 0,
                            label: context.l10n.off,
                          ),
                          const SyriusSegmentOption<int>(value: 3, label: '3'),
                          const SyriusSegmentOption<int>(value: 5, label: '5'),
                          const SyriusSegmentOption<int>(
                            value: 10,
                            label: '10',
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: tokens.border),
                    _SettingsRow(
                      title: context.l10n.password,
                      trailing: SyriusPillButton(
                        label: context.l10n.change,
                        compact: true,
                        onPressed: () {
                          NavigationUtils.push(
                            context,
                            ChangeWalletPasswordScreen(
                              onStepperNotificationSeeMorePressed:
                                  widget.onStepperNotificationSeeMorePressed,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<SettingsBackupCubit, SettingsBackupState>(
                builder: (BuildContext context, SettingsBackupState bState) {
                  final bool canBackup =
                      bState.canBackup && bState is! SettingsBackupLoading;
                  return SyriusCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                          child: Text(
                            context.l10n.backup,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: tokens.border),
                        _SettingsRow(
                          title: context.l10n.seedPhrase,
                          subtitle: context.l10n.dumpMnemonic,
                          trailing: SyriusPillButton(
                            label: context.l10n.show,
                            icon: Icons.visibility_outlined,
                            compact: true,
                            onPressed: bState.canBackup
                                ? () => NavigationUtils.push(
                                    context,
                                    const DumpMnemonicScreen(),
                                  )
                                : null,
                          ),
                        ),
                        Divider(height: 1, color: tokens.border),
                        _SettingsRow(
                          title: context.l10n.seedVault,
                          subtitle: context.l10n.backupSeedEncryptedOrClearText,
                          trailing: SyriusPillButton(
                            label: context.l10n.export,
                            icon: Icons.download_outlined,
                            compact: true,
                            isLoading: bState is SettingsBackupLoading,
                            onPressed: canBackup
                                ? () => unawaited(
                                    context
                                        .read<SettingsBackupCubit>()
                                        .requestBackupSeed(),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _SettingsCollapsibleCard(
                title: context.l10n.signAMessage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildPasteField(
                      controller: _signMsgController,
                      hintText: context.l10n.enterText,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SyriusPillButton(
                        label: context.l10n.sign,
                        isLoading: state.isSigningMessage,
                        onPressed: _signMsgController.text.isNotEmpty
                            ? () {
                                secBloc.add(
                                  SettingsSecuritySignMessageRequested(
                                    message: _signMsgController.text,
                                    errorTitle:
                                        context.l10n.errorSigningMessage,
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    if (state.signedMessageSignature.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      SyriusKeyValueRow(
                        label: context.l10n.signature,
                        labelWidth: 96,
                        value: Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                state.signedMessageSignature,
                                style: tokens.monoStyle(fontSize: 11.5),
                              ),
                            ),
                            CopyToClipboardButton(state.signedMessageSignature),
                          ],
                        ),
                      ),
                      SyriusKeyValueRow(
                        label: context.l10n.publicKey,
                        labelWidth: 96,
                        value: Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                state.signedMessagePublicKey,
                                style: tokens.monoStyle(fontSize: 11.5),
                              ),
                            ),
                            CopyToClipboardButton(state.signedMessagePublicKey),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCollapsibleCard(
                title: context.l10n.verifyASignature,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildPasteField(
                      controller: _verifyMsgController,
                      hintText: context.l10n.enterMessage,
                    ),
                    const SizedBox(height: 10),
                    _buildPasteField(
                      controller: _verifySigController,
                      hintText: context.l10n.enterSignature,
                    ),
                    const SizedBox(height: 10),
                    _buildPasteField(
                      controller: _verifyPubKeyController,
                      hintText: context.l10n.enterPublicKey,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SyriusPillButton(
                        label: context.l10n.verify,
                        isLoading: state.isVerifyingMessage,
                        onPressed:
                            _verifyMsgController.text.isNotEmpty &&
                                _verifySigController.text.isNotEmpty &&
                                _verifyPubKeyController.text.isNotEmpty
                            ? () {
                                secBloc.add(
                                  SettingsSecurityVerifyMessageRequested(
                                    message: _verifyMsgController.text,
                                    signature: _verifySigController.text,
                                    publicKey: _verifyPubKeyController.text,
                                    successTitle: context
                                        .l10n
                                        .messageVerifiedSuccessfully,
                                    successDetails: context.l10n
                                        .messageVerifiedWithSignature(
                                          _verifyMsgController.text,
                                          _verifySigController.text,
                                        ),
                                    invalidMessage:
                                        context.l10n.messageOrSignatureInvalid,
                                    errorTitle:
                                        context.l10n.errorVerifyingMessage,
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCollapsibleCard(
                title: context.l10n.signFile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SelectFileWidget(
                      key: _signFileKey,
                      onPathFoundCallback: (String path) {
                        setState(() => _signFilePath = path);
                      },
                      textStyle: TextStyle(
                        fontSize: 13,
                        color: tokens.textSecondary,
                      ),
                    ),
                    if (_signFilePath != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SyriusPillButton(
                          label: context.l10n.signFile,
                          isLoading: state.isSigningFile,
                          onPressed: () {
                            secBloc.add(
                              SettingsSecuritySignFileRequested(
                                filePath: _signFilePath!,
                                errorTitle: context.l10n.errorSigningMessage,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (state.signedFileHash.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      SyriusKeyValueRow(
                        label: context.l10n.signedHash,
                        labelWidth: 96,
                        value: Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                state.signedFileHash,
                                style: tokens.monoStyle(fontSize: 11.5),
                              ),
                            ),
                            CopyToClipboardButton(state.signedFileHash),
                          ],
                        ),
                      ),
                      SyriusKeyValueRow(
                        label: context.l10n.publicKey,
                        labelWidth: 96,
                        value: Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                state.signedFilePublicKey,
                                style: tokens.monoStyle(fontSize: 11.5),
                              ),
                            ),
                            CopyToClipboardButton(state.signedFilePublicKey),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCollapsibleCard(
                title: context.l10n.verifyFile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SelectFileWidget(
                      key: _verifyFileKey,
                      onPathFoundCallback: (String path) {
                        setState(() => _verifyFilePath = path);
                      },
                      textStyle: TextStyle(
                        fontSize: 13,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPasteField(
                      controller: _verifyFileHashController,
                      hintText: context.l10n.enterSignedHash,
                    ),
                    const SizedBox(height: 10),
                    _buildPasteField(
                      controller: _verifyFilePubKeyController,
                      hintText: context.l10n.enterPublicKey,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SyriusPillButton(
                        label: context.l10n.verifyFile,
                        isLoading: state.isVerifyingFile,
                        onPressed:
                            _verifyFilePath != null &&
                                _verifyFileHashController.text.isNotEmpty &&
                                _verifyFilePubKeyController.text.isNotEmpty
                            ? () {
                                final String signedHash =
                                    _verifyFileHashController.text;
                                secBloc.add(
                                  SettingsSecurityVerifyFileRequested(
                                    filePath: _verifyFilePath!,
                                    signedHash: signedHash,
                                    publicKey: _verifyFilePubKeyController.text,
                                    successTitle: context
                                        .l10n
                                        .fileHashVerifiedSuccessfully,
                                    successDetails: context.l10n
                                        .fileHashVerifiedWithSignedHash(
                                          signedHash,
                                        ),
                                    invalidMessage:
                                        context.l10n.hashOrPublicKeyInvalid,
                                    errorTitle:
                                        context.l10n.errorVerifyingFileHash,
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SyriusCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () =>
                      NavigationUtils.push(context, const ResetWalletScreen()),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          context.l10n.removeWallet,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.eraseWalletFilesMakeSureBackup,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: tokens.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// 4. DISPLAY (Screen 32)
// =============================================================================

class _DisplaySettingsPane extends StatelessWidget {
  const _DisplaySettingsPane();

  TextScaling _normalizeTextScale(TextScaling? raw) {
    if (raw == TextScaling.small) {
      return TextScaling.small;
    }
    if (raw == TextScaling.large || raw == TextScaling.huge) {
      return TextScaling.large;
    }
    return TextScaling.normal;
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppThemeNotifier themeNotifier = context.watch<AppThemeNotifier>();
    final TextScalingNotifier scaleNotifier = context
        .watch<TextScalingNotifier>();
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();
    final SettingsDisplayCubit displayCubit = context
        .read<SettingsDisplayCubit>();

    final ThemeMode currentTheme =
        themeNotifier.currentThemeMode ?? ThemeMode.dark;
    final TextScaling currentScale = _normalizeTextScale(
      scaleNotifier.currentTextScaling,
    );

    const List<MapEntry<String, String>> explorers = <MapEntry<String, String>>[
      MapEntry<String, String>('explorer.zenon.network', kExplorer),
      MapEntry<String, String>('zenonhub.io/explorer', kHubCommunityExplorer),
    ];

    final String activeExplorerLabel =
        explorers
            .where(
              (MapEntry<String, String> e) =>
                  e.value == uiPrefs.selectedExplorer,
            )
            .firstOrNull
            ?.key ??
        explorers.first.key;

    return SyriusCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          _SettingsRow(
            title: context.l10n.theme,
            trailing: SyriusSegmentedControl<ThemeMode>(
              selected: currentTheme,
              onChanged: (ThemeMode mode) {
                themeNotifier.changeThemeMode(mode);
                unawaited(
                  displayCubit.confirmThemeMode(
                    themeMode: mode,
                    notificationTitle: context.l10n.themeModeChanged,
                    notificationDetails: context.l10n.themeModeChangedDetails(
                      mode.name,
                    ),
                    errorTitle: context.l10n.themeModeChangeFailed,
                  ),
                );
              },
              options: <SyriusSegmentOption<ThemeMode>>[
                SyriusSegmentOption<ThemeMode>(
                  value: ThemeMode.system,
                  label: context.l10n.system,
                ),
                SyriusSegmentOption<ThemeMode>(
                  value: ThemeMode.dark,
                  label: context.l10n.dark,
                ),
                SyriusSegmentOption<ThemeMode>(
                  value: ThemeMode.light,
                  label: context.l10n.light,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _SettingsRow(
            title: context.l10n.textSize,
            trailing: SyriusSegmentedControl<TextScaling>(
              selected: currentScale,
              onChanged: (TextScaling scale) {
                scaleNotifier.changeTextScaling(scale);
                unawaited(
                  displayCubit.confirmTextScaling(
                    textScaling: scale,
                    notificationTitle: context.l10n.textScaleChanged,
                    notificationDetails: context.l10n.textScaleChangedDetails(
                      scale.name,
                    ),
                    errorTitle: context.l10n.textScaleChangeFailed,
                  ),
                );
              },
              options: <SyriusSegmentOption<TextScaling>>[
                SyriusSegmentOption<TextScaling>(
                  value: TextScaling.small,
                  label: context.l10n.small,
                ),
                SyriusSegmentOption<TextScaling>(
                  value: TextScaling.normal,
                  label: context.l10n.defaultLabel,
                ),
                SyriusSegmentOption<TextScaling>(
                  value: TextScaling.large,
                  label: context.l10n.large,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _SettingsRow(
            title: context.l10n.locale,
            trailing: SyriusPillButton(
              label: context.l10n.english,
              compact: true,
              onPressed: () {},
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _SettingsRow(
            title: context.l10n.menu,
            subtitle: context.l10n.icons,
            trailing: SyriusSegmentedControl<bool>(
              selected: uiPrefs.sidebarExpanded,
              onChanged: (bool expanded) {
                uiPrefs.sidebarExpanded = expanded;
              },
              options: <SyriusSegmentOption<bool>>[
                SyriusSegmentOption<bool>(
                  value: false,
                  label: context.l10n.icons,
                ),
                SyriusSegmentOption<bool>(
                  value: true,
                  label: context.l10n.labels,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _SettingsRow(
            title: context.l10n.hideBalances,
            trailing: Switch(
              value: uiPrefs.hideBalances,
              onChanged: (bool v) => uiPrefs.hideBalances = v,
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _SettingsRow(
            title: context.l10n.dollarValues,
            trailing: Switch(
              value: uiPrefs.showFiatValues,
              onChanged: (bool v) => uiPrefs.showFiatValues = v,
            ),
          ),
          Divider(height: 1, color: tokens.border),
          _SettingsRow(
            title: context.l10n.explorer,
            trailing: PopupMenuButton<String>(
              onSelected: uiPrefs.setSelectedExplorer,
              itemBuilder: (_) => explorers
                  .map(
                    (MapEntry<String, String> e) => PopupMenuItem<String>(
                      value: e.value,
                      child: Text(e.key),
                    ),
                  )
                  .toList(),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: tokens.surfaceSubtle,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      activeExplorerLabel,
                      style: tokens.monoStyle(
                        fontSize: 12,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: tokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. WALLET (Screen 33)
// =============================================================================

class _WalletSettingsPane extends StatelessWidget {
  const _WalletSettingsPane();

  List<String> _discoverWalletFiles() {
    try {
      final Directory dir = znnDefaultWalletDirectory;
      if (!dir.existsSync()) {
        return const <String>[];
      }
      return dir
          .listSync()
          .whereType<File>()
          .map((File f) => p.basename(f.path))
          .toList()
        ..sort();
    } on Object catch (_) {
      return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();
    final List<String> wallets = _discoverWalletFiles();

    return BlocBuilder<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      builder: (BuildContext context, SettingsWalletOptionsState state) {
        final SettingsWalletOptionsBloc bloc = context
            .read<SettingsWalletOptionsBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SyriusCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _SettingsRow(
                    title: context.l10n.autoReceiver,
                    subtitle: context.l10n.uncheckToDisableAutoReceiver,
                    trailing: Switch(
                      value: state.autoReceive,
                      onChanged: (bool enabled) {
                        final String status = enabled
                            ? context.l10n.enabled
                            : context.l10n.disabled;
                        bloc.add(
                          SettingsWalletOptionsAutoReceiveToggled(
                            enabled: enabled,
                            notificationTitle: context.l10n.autoReceiverStatus(
                              status,
                            ),
                            notificationDetails: context.l10n
                                .autoReceiverPreferenceStatus(status),
                            errorTitle:
                                context.l10n.errorSettingAutoReceivePreference,
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _SettingsRow(
                    title: context.l10n.desktopNotifications,
                    trailing: Switch(
                      value: state.enableDesktopNotifications,
                      onChanged: (bool enabled) {
                        final String status = enabled
                            ? context.l10n.enabled
                            : context.l10n.disabled;
                        bloc.add(
                          SettingsWalletOptionsDesktopNotificationsToggled(
                            enabled: enabled,
                            notificationTitle: context.l10n
                                .desktopNotificationsStatus(status),
                            notificationDetails: context.l10n
                                .desktopNotificationsPreferenceStatus(status),
                            errorTitle:
                                context.l10n.errorSettingDesktopNotifications,
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _SettingsRow(
                    title: context.l10n.launchAtStartup,
                    trailing: Switch(
                      value: state.launchAtStartup,
                      onChanged: (bool enabled) {
                        final String status = enabled
                            ? context.l10n.enabled
                            : context.l10n.disabled;
                        bloc.add(
                          SettingsWalletOptionsLaunchAtStartupToggled(
                            enabled: enabled,
                            notificationTitle: context.l10n
                                .launchAtStartupStatus(status),
                            notificationDetails: context.l10n
                                .launchAtStartupPreferenceStatus(status),
                            errorTitle:
                                context.l10n.errorSettingLaunchAtStartup,
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 1, color: tokens.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          context.l10n.modes,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: tokens.textPrimary,
                          ),
                        ),
                        _modeChipGroup(
                          context,
                          tokens,
                          label: context.l10n.pillar,
                          value: uiPrefs.pillarMode,
                          onChanged: uiPrefs.setPillarMode,
                        ),
                        _modeChipGroup(
                          context,
                          tokens,
                          label: context.l10n.sentinel,
                          value: uiPrefs.sentinelMode,
                          onChanged: uiPrefs.setSentinelMode,
                        ),
                        _modeChipGroup(
                          context,
                          tokens,
                          label: context.l10n.sporks,
                          value: uiPrefs.sporksMode,
                          onChanged: uiPrefs.setSporksMode,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _SettingsRow(
                    title: context.l10n.deleteCache,
                    subtitle: context.l10n.deleteWalletCacheAndCloseApp,
                    trailing: SyriusPillButton(
                      label: context.l10n.delete,
                      compact: true,
                      onPressed: () {
                        NavigationUtils.pushReplacement(
                          context,
                          const SplashScreen(deleteCacheFlow: true),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCollapsibleCard(
              title: context.l10n.walletsOnThisComputer,
              count: wallets.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (wallets.isEmpty)
                    Text(
                      context.l10n.noneYet,
                      style: TextStyle(fontSize: 13, color: tokens.textMuted),
                    )
                  else
                    for (final String w in wallets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 15,
                              color: tokens.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w,
                                style: tokens.monoStyle(
                                  fontSize: 12.5,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SyriusPillButton(
                      label: context.l10n.addAWallet,
                      icon: Icons.add,
                      compact: true,
                      onPressed: () {
                        NavigationUtils.push(
                          context,
                          const AccessWalletScreen(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _modeChipGroup(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required String label,
    required FeatureDisplayMode value,
    required ValueChanged<FeatureDisplayMode> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
        const SizedBox(width: 6),
        SyriusSegmentedControl<FeatureDisplayMode>(
          selected: value,
          onChanged: onChanged,
          options: <SyriusSegmentOption<FeatureDisplayMode>>[
            SyriusSegmentOption<FeatureDisplayMode>(
              value: FeatureDisplayMode.auto,
              label: context.l10n.autoLabel,
            ),
            SyriusSegmentOption<FeatureDisplayMode>(
              value: FeatureDisplayMode.on,
              label: context.l10n.onLabel,
            ),
            SyriusSegmentOption<FeatureDisplayMode>(
              value: FeatureDisplayMode.off,
              label: context.l10n.off,
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// 6. APPS (Screen 34)
// =============================================================================

class _AppsSettingsPane extends StatelessWidget {
  const _AppsSettingsPane({required this.hasWeb3});

  final bool hasWeb3;

  Future<void> _showConnectLinkDialog(BuildContext context) async {
    final TextEditingController uriController = TextEditingController(
      text: kLastWalletConnectUriNotifier.value ?? '',
    );
    final WalletConnectPairBloc pairBloc = context
        .read<WalletConnectPairBloc>();
    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 460,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final bool valid =
                extractWalletConnectUri(
                  uriController.text,
                  isWindows: Platform.isWindows,
                ) !=
                null;
            return SyriusModalShell(
              title: context.l10n.connectByLink,
              actions: <Widget>[
                SyriusPillButton(
                  label: context.l10n.cancel,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                SyriusGradientButton(
                  label: context.l10n.connect,
                  height: 36,
                  onPressed: valid
                      ? () {
                          pairBloc.add(
                            WalletConnectPairRequested(
                              rawUri: uriController.text,
                              isWindows: Platform.isWindows,
                            ),
                          );
                          Navigator.of(dialogContext).pop();
                        }
                      : null,
                ),
              ],
              child: TextField(
                controller: uriController,
                autofocus: true,
                onChanged: (_) => setModalState(() {}),
                decoration: InputDecoration(
                  hintText: context.l10n.walletConnectUri,
                  suffixIcon: PasteContentButton(
                    controller: uriController,
                    onPasted: (_) => setModalState(() {}),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    uriController.dispose();
  }

  void _disconnectSession(BuildContext context, String topic) {
    context.read<WalletConnectSessionsBloc>().add(
      WalletConnectSessionDisconnectRequested(topic: topic),
    );
  }

  void _toggleClipboardWatcher(BuildContext context, {required bool enabled}) {
    final String status = enabled
        ? context.l10n.enabled
        : context.l10n.disabled;
    context.read<SettingsWalletOptionsBloc>().add(
      SettingsWalletOptionsClipboardWatcherToggled(
        enabled: enabled,
        notificationTitle: context.l10n.clipboardWatcherStatus(status),
        notificationDetails: context.l10n.clipboardWatcherPreferenceStatus(
          status,
        ),
        errorTitle: context.l10n.errorChangingClipboardWatcher,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SyriusCard(
          padding: EdgeInsets.zero,
          child: _SettingsRow(
            title: context.l10n.webApps,
            subtitle: '127.0.0.1:35996',
            trailing: Switch(
              value: uiPrefs.webAppsEnabled,
              onChanged: (bool v) => uiPrefs.webAppsEnabled = v,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!hasWeb3)
          SyriusCard(child: SyriusEmptyState(message: context.l10n.noneYet))
        else ...<Widget>[
          BlocBuilder<WalletConnectSessionsBloc, WalletConnectSessionsState>(
            builder: (BuildContext context, WalletConnectSessionsState sState) {
              return SyriusCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                      child: Row(
                        children: <Widget>[
                          Text(
                            context.l10n.connected,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${sState.sessions.length}',
                            style: tokens.monoStyle(
                              fontSize: 12.5,
                              color: tokens.textMuted,
                            ),
                          ),
                          const Spacer(),
                          SyriusPillButton(
                            label: context.l10n.connectByLink,
                            icon: Icons.add,
                            compact: true,
                            onPressed: () =>
                                unawaited(_showConnectLinkDialog(context)),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: tokens.border),
                    if (sState.sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.noneYet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textMuted,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sState.sessions.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: tokens.border),
                        itemBuilder: (BuildContext context, int index) {
                          final SessionData session = sState.sessions[index];
                          final String site = walletConnectDisplayValue(
                            session.peer.metadata.name,
                            session.peer.metadata.url,
                          );
                          final bool disconnecting = sState.disconnectingTopics
                              .contains(session.topic);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              children: <Widget>[
                                SyriusTokenAvatar(symbol: site, size: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    site,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formatWalletConnectExpiry(session.expiry),
                                    style: tokens.monoStyle(
                                      fontSize: 12,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    context.l10n.walletConnect,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                ),
                                SyriusGhostButton(
                                  label: disconnecting
                                      ? '...'
                                      : context.l10n.disconnect,
                                  onPressed: disconnecting
                                      ? null
                                      : () => _disconnectSession(
                                          context,
                                          session.topic,
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          BlocBuilder<WalletConnectPairingsBloc, WalletConnectPairingsState>(
            builder: (BuildContext context, WalletConnectPairingsState pState) {
              return _SettingsCollapsibleCard(
                title: context.l10n.walletConnect,
                trailingSummary: '${pState.pairings.length} pairings',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    BlocBuilder<
                      SettingsWalletOptionsBloc,
                      SettingsWalletOptionsState
                    >(
                      builder:
                          (
                            BuildContext context,
                            SettingsWalletOptionsState wState,
                          ) {
                            return Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    context.l10n.enableClipboardWatcher,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: wState.enableClipboardWatcher,
                                  onChanged: (bool enabled) =>
                                      _toggleClipboardWatcher(
                                        context,
                                        enabled: enabled,
                                      ),
                                ),
                              ],
                            );
                          },
                    ),
                    if (pState.pairings.isNotEmpty) ...<Widget>[
                      Divider(height: 20, color: tokens.border),
                      for (final PairingInfo pairing in pState.pairings)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  walletConnectDisplayValue(
                                    pairing.peerMetadata?.name,
                                    pairing.topic.short,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                              SyriusGhostButton(
                                label: context.l10n.delete,
                                onPressed: () {
                                  context.read<WalletConnectPairingsBloc>().add(
                                    WalletConnectPairingDeactivateRequested(
                                      topic: pairing.topic,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// 7. ABOUT + LICENCES + ORIGINALS EASTER EGG (Screens 36–38)
// =============================================================================

class _AboutSettingsPane extends StatefulWidget {
  const _AboutSettingsPane();

  @override
  State<_AboutSettingsPane> createState() => _AboutSettingsPaneState();
}

class _AboutSettingsPaneState extends State<_AboutSettingsPane> {
  final TextEditingController _easterEggController = TextEditingController();
  late final Future<List<MapEntry<String, String>>> _licensesFuture;
  bool _showOriginals = false;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadPackageLicenses();
  }

  Future<List<MapEntry<String, String>>> _loadPackageLicenses() async {
    final Map<String, StringBuffer> grouped = <String, StringBuffer>{};
    await for (final LicenseEntry entry in LicenseRegistry.licenses) {
      final String text = entry.paragraphs
          .map((LicenseParagraph p) => p.text)
          .join('\n\n');
      for (final String pkg in entry.packages) {
        grouped.putIfAbsent(pkg, StringBuffer.new).writeln(text);
      }
    }
    final List<MapEntry<String, String>> list =
        grouped.entries
            .map(
              (MapEntry<String, StringBuffer> e) =>
                  MapEntry<String, String>(e.key, e.value.toString().trim()),
            )
            .toList()
          ..sort(
            (MapEntry<String, String> a, MapEntry<String, String> b) =>
                a.key.compareTo(b.key),
          );
    return list;
  }

  @override
  void dispose() {
    _easterEggController.dispose();
    super.dispose();
  }

  Future<void> _showLaunchReplayDialog(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (BuildContext ctx, _, _) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                Center(
                  child: Lottie.asset(
                    'assets/lottie/ic_anim_splash.json',
                    repeat: false,
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      context.l10n.clickOrPressAKeyToSkip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final List<MapEntry<String, String>> communityLinks =
        <MapEntry<String, String>>[
          MapEntry<String, String>(context.l10n.zenonNetwork, kWebsite),
          MapEntry<String, String>(
            context.l10n.zenonOrgCommunityForum,
            kOrgCommunityForum,
          ),
          MapEntry<String, String>(context.l10n.zenonTools, kTools),
          MapEntry<String, String>(
            context.l10n.zenonOrgCommunity,
            kOrgCommunityWebsite,
          ),
          MapEntry<String, String>(context.l10n.zenonHub, kHubCommunityWebsite),
          MapEntry<String, String>(context.l10n.zenonExplorer, kExplorer),
          MapEntry<String, String>(
            context.l10n.zenonHubExplorer,
            kHubCommunityExplorer,
          ),
          MapEntry<String, String>(context.l10n.zenonTwitter, kTwitter),
          MapEntry<String, String>(context.l10n.zenonDiscord, kDiscord),
          MapEntry<String, String>(context.l10n.zenonTelegram, kTelegram),
          MapEntry<String, String>(context.l10n.zenonMedium, kMedium),
          MapEntry<String, String>(context.l10n.zenonGithub, kGithub),
          MapEntry<String, String>(context.l10n.zenonBitcoinTalk, kBitcoinTalk),
          MapEntry<String, String>(context.l10n.zenonReddit, kReddit),
          MapEntry<String, String>(context.l10n.zenonYoutube, kYoutube),
          MapEntry<String, String>(context.l10n.zenonWiki, kWiki),
          MapEntry<String, String>(
            context.l10n.zenonOrgCommunityWiki,
            kOrgCommunityWiki,
          ),
          MapEntry<String, String>(context.l10n.zenonWhitepaper, kWhitepaper),
        ];

    return BlocBuilder<AboutBloc, AboutState>(
      builder: (BuildContext context, AboutState aboutState) {
        final AboutNodeInfo nodeInfo = aboutState is AboutPopulated
            ? aboutState.nodeInfo
            : const AboutNodeInfo();
        final String shortCommit = gitCommitHash.length > 7
            ? gitCommitHash.substring(0, 7)
            : gitCommitHash;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SyriusCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: <Widget>[
                  const SyriusMetricBlock(
                    label: 'Syrius',
                    value: kWalletVersion,
                  ),
                  const SizedBox(width: 28),
                  SyriusMetricBlock(
                    label: context.l10n.embeddedNode,
                    value: nodeInfo.processInfo?.version ?? 'bundled',
                  ),
                  const SizedBox(width: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('BUILD', style: tokens.microLabelStyle()),
                      const SizedBox(height: 6),
                      Text(
                        '$shortCommit · $gitCommitDate',
                        style: tokens.monoStyle(
                          fontSize: 12.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SyriusPillButton(
                    label: context.l10n.whatChanged,
                    compact: true,
                    onPressed: () =>
                        unawaited(NavigationUtils.openUrl(kGithubReleasesLink)),
                  ),
                  const SizedBox(width: 10),
                  SyriusGradientButton(
                    label: context.l10n.checkUpdate,
                    icon: Icons.download_outlined,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    onPressed: () =>
                        unawaited(NavigationUtils.openUrl(kGithubReleasesLink)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCollapsibleCard(
              title: context.l10n.links,
              count: communityLinks.length,
              trailingSummary: context.l10n.community,
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: communityLinks
                    .map(
                      (MapEntry<String, String> item) => SizedBox(
                        width: 240,
                        child: InkWell(
                          onTap: () =>
                              unawaited(NavigationUtils.openUrl(item.value)),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.key,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  size: 13,
                                  color: tokens.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCollapsibleCard(
              title: context.l10n.thisComputer,
              trailingSummary: Platform.operatingSystem,
              child: Column(
                children: <Widget>[
                  _computerPathRow(
                    tokens,
                    context.l10n.zenonMainDataPath,
                    znnDefaultPaths.main.absolute.path,
                  ),
                  _computerPathRow(
                    tokens,
                    context.l10n.syriusCachePath,
                    znnDefaultPaths.cache.absolute.path,
                  ),
                  _computerPathRow(
                    tokens,
                    context.l10n.syriusWalletPath,
                    znnDefaultPaths.wallet.absolute.path,
                  ),
                  SyriusKeyValueRow(
                    label: context.l10n.syriusWalletType,
                    labelWidth: 165,
                    value: Text(
                      kWalletFile?.walletType ?? '-',
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: context.l10n.zenonSdkVersion,
                    labelWidth: 165,
                    value: Text(
                      znnSdkVersion,
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: context.l10n.clientHostname,
                    labelWidth: 165,
                    value: Text(
                      Platform.localHostname,
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: context.l10n.clientOperatingSystem,
                    labelWidth: 165,
                    value: Text(
                      '${Platform.operatingSystem} '
                      '(${Platform.numberOfProcessors} CPU)',
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCollapsibleCard(
              title: context.l10n.licences,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FutureBuilder<List<MapEntry<String, String>>>(
                    future: _licensesFuture,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<MapEntry<String, String>>> snap,
                        ) {
                          final List<MapEntry<String, String>> packages =
                              snap.data ?? const <MapEntry<String, String>>[];
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: SyriusLoadingWidget(),
                            );
                          }
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: packages.length,
                              separatorBuilder: (_, _) =>
                                  Divider(height: 1, color: tokens.border),
                              itemBuilder: (BuildContext context, int index) {
                                final MapEntry<String, String> pkg =
                                    packages[index];
                                return InkWell(
                                  onTap: () {
                                    unawaited(
                                      showSyriusBlurredDialog<void>(
                                        context: context,
                                        maxWidth: 560,
                                        builder: (_) => SyriusModalShell(
                                          title: pkg.key,
                                          child: SelectableText(
                                            pkg.value,
                                            style: tokens.monoStyle(
                                              fontSize: 11.5,
                                              color: tokens.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            pkg.key,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: tokens.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 15,
                                          color: tokens.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      key: const Key('licences_easter_egg_field'),
                      controller: _easterEggController,
                      onChanged: (String value) {
                        final bool unlocked = value.trim() == '321';
                        if (unlocked != _showOriginals) {
                          setState(() => _showOriginals = unlocked);
                        }
                      },
                      style: tokens.monoStyle(),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showOriginals) ...<Widget>[
              const SizedBox(height: 14),
              _OriginalsGalleryCard(
                onPlayLaunch: () => unawaited(_showLaunchReplayDialog(context)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _computerPathRow(SyriusThemeTokens tokens, String label, String path) {
    return SyriusKeyValueRow(
      label: label,
      labelWidth: 165,
      value: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              path,
              overflow: TextOverflow.ellipsis,
              style: tokens.monoStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ),
          CopyToClipboardButton(path),
          IconButton(
            iconSize: 15,
            splashRadius: 15,
            color: tokens.textMuted,
            onPressed: () => unawaited(OpenFilex.open(path)),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }
}

/// Originals classic Syrius Lottie animation gallery (Screen 38).
class _OriginalsGalleryCard extends StatelessWidget {
  const _OriginalsGalleryCard({required this.onPlayLaunch});

  final VoidCallback onPlayLaunch;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    const List<_OriginalAssetSpec> showcase = <_OriginalAssetSpec>[
      _OriginalAssetSpec(
        asset: 'assets/lottie/ic_anim_splash.json',
        title: 'Launch',
        subtitle: 'Every start, then the lock card',
        pureBlack: true,
      ),
      _OriginalAssetSpec(
        asset: 'assets/lottie/ic_anim_welcome.json',
        title: 'Globe',
        subtitle: 'Welcome',
      ),
      _OriginalAssetSpec(
        asset: 'assets/lottie/ic_anim_map.json',
        title: 'Map',
        subtitle: 'Wallet ready',
      ),
      _OriginalAssetSpec(
        asset: 'assets/lottie/ic_anim_pillar.json',
        title: 'Pillar',
        subtitle: 'Your pillar, Spawn',
      ),
      _OriginalAssetSpec(
        asset: 'assets/lottie/ic_anim_sentinel.json',
        title: 'Sentinel',
        subtitle: 'Your sentinel, Spawn',
      ),
      _OriginalAssetSpec(
        asset: 'assets/lottie/ic_anim_zts.json',
        title: 'ZTS',
        subtitle: 'Tokens, Create token',
      ),
    ];

    return SyriusCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                context.l10n.originals,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'SINCE SYRIUS 0.0.5, APRIL 2022',
                style: tokens.monoStyle(
                  fontSize: 10.5,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              SyriusPillButton(
                label: context.l10n.playLaunch,
                icon: Icons.replay_rounded,
                compact: true,
                onPressed: onPlayLaunch,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int cols = constraints.maxWidth > 720 ? 6 : 3;
              const double spacing = 12;
              final double tileWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: 14,
                children: showcase
                    .map(
                      (_OriginalAssetSpec spec) => SizedBox(
                        width: tileWidth,
                        child: _HoverLottieTile(spec: spec),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: tokens.border),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _microLottie(
                tokens,
                'assets/lottie/ic_anim_plasma_generation.json',
                'Generating plasma, in the strip',
              ),
              const SizedBox(width: 22),
              _microLottie(
                tokens,
                'assets/lottie/ic_anim_eye.json',
                'Hidden balances',
              ),
              const SizedBox(width: 22),
              _microLottie(
                tokens,
                'assets/lottie/ic_anim_no_data.json',
                'Empty lists',
              ),
              const Spacer(),
              Text(
                'Hover to play',
                style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _microLottie(SyriusThemeTokens tokens, String asset, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox.square(
          dimension: 18,
          child: Lottie.asset(asset, repeat: true),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
      ],
    );
  }
}

class _OriginalAssetSpec {
  const _OriginalAssetSpec({
    required this.asset,
    required this.title,
    required this.subtitle,
    this.pureBlack = false,
  });

  final String asset;
  final String title;
  final String subtitle;
  final bool pureBlack;
}

class _HoverLottieTile extends StatefulWidget {
  const _HoverLottieTile({required this.spec});

  final _OriginalAssetSpec spec;

  @override
  State<_HoverLottieTile> createState() => _HoverLottieTileState();
}

class _HoverLottieTileState extends State<_HoverLottieTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.25,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.spec.pureBlack
                    ? Colors.black
                    : tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hovered ? tokens.znnGreen : tokens.border,
                ),
              ),
              child: Lottie.asset(
                widget.spec.asset,
                animate: _hovered,
                repeat: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.spec.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.spec.subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: tokens.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
