import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Active sub-tab inside the unified Nodes workspace (Screens 16–18).
enum NodesSubTab {
  /// Network Pillars & delegation view.
  pillars,

  /// Network Sentinels view.
  sentinels,
}

/// Displays the unified Nodes tab defaulting to Pillars (Screens 16–17).
class PillarsTabChild extends StatelessWidget {
  /// Creates a [PillarsTabChild].
  const PillarsTabChild({
    required this._onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return NodesWorkspaceView(
      initialTab: NodesSubTab.pillars,
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
    );
  }
}

/// Unified Nodes screen combining Pillars (delegation + My Pillar management)
/// and Sentinels into one clean tabbed workspace (Screens 16–18).
class NodesWorkspaceView extends StatefulWidget {
  /// Creates a [NodesWorkspaceView].
  const NodesWorkspaceView({
    required this.initialTab,
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  /// Initial sub-tab selected when mounted.
  final NodesSubTab initialTab;

  /// Callback passed into Pillar/Sentinel creation and update steppers.
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<NodesWorkspaceView> createState() => _NodesWorkspaceViewState();
}

enum _PillarSortField { weight, uptime, name }

class _NodesWorkspaceViewState extends State<NodesWorkspaceView> {
  static final NumberFormat _intFormat = NumberFormat.decimalPattern();
  static final NumberFormat _compactFormat = NumberFormat.compact();
  static final NumberFormat _amountFormat = NumberFormat('#,##0.###');

  late NodesSubTab _activeSubTab = widget.initialTab;
  bool _showMyPillarPanel = false;
  final TextEditingController _searchController = TextEditingController();
  _PillarSortField _sortField = _PillarSortField.weight;
  String? _expandedPillarName;
  String? _delegatingPillarName;
  bool _collecting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Address address = Address.parse(kSelectedAddress!);
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<PillarsBloc>(
          create: (_) =>
              PillarsBloc(zenon: zenon!)..add(const InfiniteListRequested()),
        ),
        BlocProvider<SentinelsBloc>(
          create: (_) =>
              SentinelsBloc(zenon: zenon!)..add(const InfiniteListRequested()),
        ),
        BlocProvider<SentinelsByOwnerBloc>(
          create: (_) =>
              SentinelsByOwnerBloc(zenon: zenon!)
                ..add(FetchRequestData(address: address)),
        ),
        BlocProvider<UncollectedPillarRewardsBloc>(
          create: (_) =>
              UncollectedPillarRewardsBloc(zenon: zenon!)
                ..add(FetchRequestData(address: address)),
        ),
        BlocProvider<UncollectedSentinelRewardsBloc>(
          create: (_) =>
              UncollectedSentinelRewardsBloc(zenon: zenon!)
                ..add(FetchRequestData(address: address)),
        ),
        BlocProvider<DelegationBloc>(
          create: (_) => DelegationBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
        BlocProvider<UndelegateBloc>(
          create: (_) => UndelegateBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
        BlocProvider<SendTransactionBloc>(create: (_) => SendTransactionBloc()),
      ],
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        BlocListener<DelegationBloc, DelegationState>(
          listener: (BuildContext context, DelegationState state) {
            if (state is DelegationDone) {
              setState(() => _delegatingPillarName = null);
              context.read<DelegationStatsBloc>().add(
                FetchRequestData(address: Address.parse(kSelectedAddress!)),
              );
            } else if (state is DelegationFailure) {
              setState(() => _delegatingPillarName = null);
              unawaited(
                NotificationUtils.sendNotificationError(
                  state.exception,
                  context.l10n.pillarDelegationError,
                ),
              );
            }
          },
        ),
        BlocListener<UndelegateBloc, UndelegateState>(
          listener: (BuildContext context, UndelegateState state) {
            if (state is UndelegateDone) {
              context.read<DelegationStatsBloc>().add(
                FetchRequestData(address: Address.parse(kSelectedAddress!)),
              );
            } else if (state is UndelegateFailure) {
              unawaited(
                NotificationUtils.sendNotificationError(
                  state.exception,
                  context.l10n.pillarDelegationError,
                ),
              );
            }
          },
        ),
        BlocListener<SendTransactionBloc, SendTransactionState>(
          listener: (BuildContext context, SendTransactionState state) {
            if (state.status == SendTransactionStatus.success) {
              setState(() => _collecting = false);
              final Address addr = Address.parse(kSelectedAddress!);
              context.read<UncollectedPillarRewardsBloc>().add(
                FetchRequestData(address: addr),
              );
              context.read<UncollectedSentinelRewardsBloc>().add(
                FetchRequestData(address: addr),
              );
            } else if (state.status == SendTransactionStatus.failure) {
              setState(() => _collecting = false);
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_activeSubTab == NodesSubTab.pillars)
            _buildPillarTopBar(context, tokens, uiPrefs)
          else
            _buildSentinelTopBar(context, tokens, uiPrefs),
          if (_activeSubTab == NodesSubTab.pillars && _showMyPillarPanel)
            _buildOwnedPillarSection(context, tokens, uiPrefs),
          const SizedBox(height: 12),
          Expanded(child: _buildTableCard(context, tokens, uiPrefs)),
        ],
      ),
    );
  }

  Widget _buildPillarTopBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final FetchState<DelegationInfo> delState = context
        .watch<DelegationStatsBloc>()
        .state;
    final DelegationInfo? delInfo = delState is FetchPopulated<DelegationInfo>
        ? delState.data
        : null;

    final FetchState<List<PillarInfo>> ownedState = context
        .watch<PillarsByOwnerBloc>()
        .state;
    final PillarInfo? ownedPillar = _selectedOwnedPillar(ownedState);

    final FetchState<UncollectedReward> uncollectedState = context
        .watch<UncollectedPillarRewardsBloc>()
        .state;
    final BigInt uncollectedZnn =
        uncollectedState is FetchPopulated<UncollectedReward>
        ? uncollectedState.data.znnAmount
        : BigInt.zero;
    final BigInt uncollectedQsr =
        uncollectedState is FetchPopulated<UncollectedReward>
        ? uncollectedState.data.qsrAmount
        : BigInt.zero;
    final bool canCollect =
        uncollectedZnn > BigInt.zero || uncollectedQsr > BigInt.zero;

    if (_showMyPillarPanel && ownedPillar != null) {
      return SyriusCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 40,
              child: Lottie.asset(
                'assets/lottie/ic_anim_pillar.json',
                repeat: false,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.yourPillar.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      ownedPillar.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SyriusStatusBadge(
                      label: context.l10n.producing,
                      tone: SyriusBadgeTone.success,
                      leadingDot: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 28),
            SyriusMetricBlock(
              label: context.l10n.toCollect,
              value: uiPrefs.hideBalances
                  ? '••••'
                  : _formatRaw(uncollectedZnn, kZnnCoin.decimals),
              valueSuffix: kZnnCoin.symbol,
              suffixColor: tokens.znnGreen,
            ),
            const SizedBox(width: 18),
            SyriusPillButton(
              label: context.l10n.collect,
              isLoading: _collecting,
              onPressed: canCollect
                  ? () => _collectPillarRewards(context)
                  : null,
            ),
            const Spacer(),
            SyriusPillButton(
              label: context.l10n.close,
              icon: Icons.close_rounded,
              height: 36,
              onPressed: () => setState(() => _showMyPillarPanel = false),
            ),
          ],
        ),
      );
    }

    final MultipleBalanceState balState = context
        .watch<MultipleBalanceBloc>()
        .state;
    final BigInt weightZnn =
        balState.data?[kSelectedAddress]?.znn() ?? BigInt.zero;

    return SyriusCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.delegatedTo.toUpperCase(),
                style: tokens.microLabelStyle(),
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Text(
                    delInfo?.name ?? context.l10n.noneYet,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: delInfo != null
                          ? tokens.textPrimary
                          : tokens.textMuted,
                    ),
                  ),
                  if (delInfo != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(
                      '· ${uiPrefs.hideBalances ? '••••' : _formatRaw(
                            weightZnn,
                            kZnnCoin.decimals,
                          )} ZNN weight',
                      style: tokens.monoStyle(
                        fontSize: 12.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (delInfo != null) ...<Widget>[
            const SizedBox(width: 16),
            SyriusPillButton(
              label: context.l10n.undelegate,
              compact: true,
              onPressed: () {
                context.read<UndelegateBloc>().add(
                  UndelegateRequested(
                    address: Address.parse(kSelectedAddress!),
                  ),
                );
              },
            ),
          ],
          const SizedBox(width: 28),
          SyriusMetricBlock(
            label: context.l10n.toCollect,
            value: uiPrefs.hideBalances
                ? '••••'
                : _formatRaw(uncollectedZnn, kZnnCoin.decimals),
            valueSuffix: kZnnCoin.symbol,
            suffixColor: tokens.znnGreen,
          ),
          const SizedBox(width: 16),
          SyriusPillButton(
            label: context.l10n.collect,
            isLoading: _collecting,
            onPressed: canCollect ? () => _collectPillarRewards(context) : null,
          ),
          const Spacer(),
          if (ownedPillar != null) ...<Widget>[
            SyriusPillButton(
              label: ownedPillar.name,
              icon: Icons.layers_rounded,
              compact: true,
              onPressed: () => setState(() => _showMyPillarPanel = true),
            ),
            const SizedBox(width: 10),
          ],
          SyriusGhostButton(
            label: context.l10n.rewards,
            icon: Icons.bar_chart_rounded,
            onPressed: () => _showRewardsModal(context, isSentinel: false),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            color: tokens.surface,
            icon: Icon(Icons.more_horiz, color: tokens.textSecondary),
            onSelected: (String value) {
              if (value == 'spawn') {
                unawaited(_openSpawnPillar(context));
              } else if (value == 'mine' && ownedPillar != null) {
                setState(() => _showMyPillarPanel = true);
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              if (ownedPillar != null)
                PopupMenuItem<String>(
                  value: 'mine',
                  child: Text(
                    context.l10n.yourPillar,
                    style: TextStyle(color: tokens.textPrimary),
                  ),
                ),
              PopupMenuItem<String>(
                value: 'spawn',
                child: Text(
                  context.l10n.spawnPillar,
                  style: TextStyle(color: tokens.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PillarInfo? _selectedOwnedPillar(FetchState<List<PillarInfo>> ownedState) {
    if (ownedState is! FetchPopulated<List<PillarInfo>> ||
        ownedState.data.isEmpty) {
      return null;
    }
    return ownedState.data.firstWhere(
      (PillarInfo item) => item.name == _expandedPillarName,
      orElse: () => ownedState.data.first,
    );
  }

  Widget _buildOwnedPillarSection(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final FetchState<List<PillarInfo>> ownedState = context
        .watch<PillarsByOwnerBloc>()
        .state;
    final PillarInfo? p = _selectedOwnedPillar(ownedState);
    if (p == null) {
      return const SizedBox.shrink();
    }
    final double uptime = p.expectedMomentums > 0
        ? (p.producedMomentums / p.expectedMomentums) * 100
        : 0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SyriusCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 112,
              child: Lottie.asset(
                'assets/lottie/ic_anim_pillar.json',
                repeat: false,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SyriusKeyValueRow(
                    label: 'LOCKED',
                    value: Text(
                      '15,000 ZNN',
                      style: tokens.monoStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: 'PRODUCER',
                    value: Row(
                      children: <Widget>[
                        Text(
                          _shorten(p.producerAddress.toString()),
                          style: tokens.monoStyle(
                            fontSize: 12.5,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => unawaited(
                            Clipboard.setData(
                              ClipboardData(text: p.producerAddress.toString()),
                            ),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: 'REWARD',
                    value: Text(
                      _shorten(p.withdrawAddress.toString()),
                      style: tokens.monoStyle(
                        fontSize: 12.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: 'MOMENTUMS',
                    value: Text(
                      '${_intFormat.format(p.producedMomentums)} of '
                      '${_intFormat.format(p.expectedMomentums)} · '
                      '${uptime.toStringAsFixed(1)}%',
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SyriusKeyValueRow(
                    label: 'REVOCABLE',
                    value: Align(
                      alignment: Alignment.centerLeft,
                      child: p.isRevocable
                          ? SyriusStatusBadge(
                              label: context.l10n.unlocked,
                              tone: SyriusBadgeTone.success,
                            )
                          : SyriusStatusBadge(
                              label: _formatCooldown(p.revokeCooldown),
                              tone: SyriusBadgeTone.info,
                              icon: Icons.schedule_rounded,
                            ),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: 'SHARING',
                    value: Text(
                      '${p.giveMomentumRewardPercentage}% block · '
                      '${p.giveDelegateRewardPercentage}% delegate',
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                  SyriusKeyValueRow(
                    label: 'WEIGHT',
                    value: Text(
                      '${_compactFormat.format(
                        double.tryParse(
                              p.weight.addDecimals(kZnnCoin.decimals),
                            ) ??
                            0,
                      )} ZNN',
                      style: tokens.monoStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 158,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SyriusPillButton(
                    label: context.l10n.update,
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => StepperScreen(
                              breadcrumbParent: context.l10n.nodes,
                              title: context.l10n.updatePillar,
                              stepper: UpdatePillarStepperPage(pillarInfo: p),
                              onStepperNotificationSeeMorePressed:
                                  widget.onStepperNotificationSeeMorePressed,
                            ),
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: 8),
                  SyriusPillButton(
                    label: context.l10n.spawn,
                    icon: Icons.add_rounded,
                    onPressed: () => _openSpawnPillar(context),
                  ),
                  if (p.isRevocable) ...<Widget>[
                    const SizedBox(height: 8),
                    RevokePillarButton(
                      pillarName: p.name,
                      onRevoked: () {
                        context.read<PillarsBloc>().add(
                          const InfiniteListRefreshRequested(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentinelTopBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final FetchState<List<SentinelInfo>> ownedState = context
        .watch<SentinelsByOwnerBloc>()
        .state;
    final SentinelInfo? owned =
        ownedState is FetchPopulated<List<SentinelInfo>> &&
            ownedState.data.isNotEmpty
        ? ownedState.data.first
        : null;
    final FetchState<UncollectedReward> rewardState = context
        .watch<UncollectedSentinelRewardsBloc>()
        .state;
    final BigInt znnAmt = rewardState is FetchPopulated<UncollectedReward>
        ? rewardState.data.znnAmount
        : BigInt.zero;
    final BigInt qsrAmt = rewardState is FetchPopulated<UncollectedReward>
        ? rewardState.data.qsrAmount
        : BigInt.zero;
    final bool canCollect = znnAmt > BigInt.zero || qsrAmt > BigInt.zero;

    return SyriusCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          SizedBox.square(
            dimension: 38,
            child: Lottie.asset(
              'assets/lottie/ic_anim_sentinel.json',
              repeat: false,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.yourSentinel.toUpperCase(),
                style: tokens.microLabelStyle(),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(
                    owned != null
                        ? ZenonAddressUtils.getLabel(owned.owner.toString())
                        : context.l10n.noneYet,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: owned != null
                          ? tokens.textPrimary
                          : tokens.textMuted,
                    ),
                  ),
                  if (owned != null && owned.active) ...<Widget>[
                    const SizedBox(width: 10),
                    SyriusStatusBadge(
                      label: context.l10n.active,
                      tone: SyriusBadgeTone.success,
                      leadingDot: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(width: 28),
          SyriusMetricBlock(
            label: context.l10n.toCollect,
            value: uiPrefs.hideBalances
                ? '••••'
                : _formatRaw(znnAmt, kZnnCoin.decimals),
            valueSuffix:
                'ZNN · ${uiPrefs.hideBalances ? '••••' : _formatRaw(
                      qsrAmt,
                      kQsrCoin.decimals,
                    )} QSR',
            suffixColor: tokens.textSecondary,
          ),
          const SizedBox(width: 16),
          SyriusPillButton(
            label: context.l10n.collect,
            isLoading: _collecting,
            onPressed: canCollect
                ? () => _collectSentinelRewards(context)
                : null,
          ),
          if (owned != null) ...<Widget>[
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('REVOCABLE', style: tokens.microLabelStyle()),
                const SizedBox(height: 5),
                SyriusStatusBadge(
                  label: owned.isRevocable
                      ? 'now'
                      : _formatCooldown(owned.revokeCooldown),
                  tone: owned.isRevocable
                      ? SyriusBadgeTone.success
                      : SyriusBadgeTone.info,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
          ],
          const Spacer(),
          SyriusGhostButton(
            label: context.l10n.rewards,
            icon: Icons.bar_chart_rounded,
            onPressed: () => _showRewardsModal(context, isSentinel: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final int pillarsCount =
        context.watch<PillarsBloc>().state.data?.length ?? 0;
    final int sentinelsCount =
        context.watch<SentinelsBloc>().state.data?.length ?? 0;

    return SyriusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
            child: Row(
              children: <Widget>[
                _UnderlineTabButton(
                  label: context.l10n.pillars,
                  count: pillarsCount,
                  active: _activeSubTab == NodesSubTab.pillars,
                  onTap: () =>
                      setState(() => _activeSubTab = NodesSubTab.pillars),
                ),
                const SizedBox(width: 20),
                _UnderlineTabButton(
                  label: context.l10n.sentinels,
                  count: sentinelsCount,
                  active: _activeSubTab == NodesSubTab.sentinels,
                  onTap: () =>
                      setState(() => _activeSubTab = NodesSubTab.sentinels),
                ),
                const Spacer(),
                if (_activeSubTab == NodesSubTab.pillars) ...<Widget>[
                  SyriusSearchField(
                    controller: _searchController,
                    hintText: context.l10n.searchScreensPlaceholder,
                    width: 200,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(width: 8),
                  SyriusPillButton(
                    label: switch (_sortField) {
                      _PillarSortField.weight => context.l10n.weight,
                      _PillarSortField.uptime => 'Uptime',
                      _PillarSortField.name => context.l10n.name,
                    },
                    icon: Icons.swap_vert_rounded,
                    compact: true,
                    onPressed: () {
                      setState(() {
                        final int next =
                            (_sortField.index + 1) %
                            _PillarSortField.values.length;
                        _sortField = _PillarSortField.values[next];
                      });
                    },
                  ),
                ] else
                  SyriusPillButton(
                    label: context.l10n.spawn,
                    icon: Icons.add_rounded,
                    compact: true,
                    onPressed: () => _openSpawnSentinel(context),
                  ),
              ],
            ),
          ),
          const SyriusDivider(),
          Expanded(
            child: _activeSubTab == NodesSubTab.pillars
                ? _buildPillarsList(context, tokens, uiPrefs)
                : _buildSentinelsList(context, tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsList(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final FetchState<DelegationInfo> delState = context
        .watch<DelegationStatsBloc>()
        .state;
    final String? delegatedName = delState is FetchPopulated<DelegationInfo>
        ? delState.data.name
        : null;
    final MultipleBalanceState balState = context
        .watch<MultipleBalanceBloc>()
        .state;
    final BigInt znnBal =
        balState.data?[kSelectedAddress]?.znn() ?? BigInt.zero;
    final bool canDelegate = znnBal >= kMinDelegationAmount;

    return BlocBuilder<PillarsBloc, InfiniteListState<PillarInfo>>(
      builder: (BuildContext context, InfiniteListState<PillarInfo> state) {
        return switch (state.status) {
          InfiniteListStatus.initial => const SyriusLoadingWidget(),
          InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
          InfiniteListStatus.success => _buildPillarsTable(
            context,
            tokens,
            uiPrefs,
            pillars: state.data ?? const <PillarInfo>[],
            hasReachedMax: state.hasReachedMax,
            delegatedName: delegatedName,
            canDelegate: canDelegate,
          ),
        };
      },
    );
  }

  Widget _buildPillarsTable(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs, {
    required List<PillarInfo> pillars,
    required bool hasReachedMax,
    required String? delegatedName,
    required bool canDelegate,
  }) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<PillarInfo> filtered = pillars
        .where(
          (PillarInfo p) =>
              query.isEmpty ||
              p.name.toLowerCase().contains(query) ||
              p.producerAddress.toString().toLowerCase().contains(query),
        )
        .toList();

    switch (_sortField) {
      case _PillarSortField.weight:
        filtered.sort(
          (PillarInfo a, PillarInfo b) => b.weight.compareTo(a.weight),
        );
      case _PillarSortField.uptime:
        filtered.sort((PillarInfo a, PillarInfo b) {
          final double ua = a.expectedMomentums > 0
              ? a.producedMomentums / a.expectedMomentums
              : 0;
          final double ub = b.expectedMomentums > 0
              ? b.producedMomentums / b.expectedMomentums
              : 0;
          return ub.compareTo(ua);
        });
      case _PillarSortField.name:
        filtered.sort(
          (PillarInfo a, PillarInfo b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }

    if (filtered.isEmpty && hasReachedMax) {
      return SyriusEmptyState(message: context.l10n.noneYet);
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(
                  context.l10n.name.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.weight.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'SHARES',
                  textAlign: TextAlign.right,
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'UPTIME',
                  textAlign: TextAlign.right,
                  style: tokens.microLabelStyle(),
                ),
              ),
              const SizedBox(width: 120),
            ],
          ),
        ),
        const SyriusDivider(),
        Expanded(
          child: SyriusPaginatedListView(
            itemCount: filtered.length,
            hasReachedMax: hasReachedMax,
            isLoadingMore: context.read<PillarsBloc>().isLoadingMoreListenable,
            dataIdentity: pillars,
            separatorBuilder: (_, _) => const SyriusDivider(),
            onLoadMore: () => context.read<PillarsBloc>().add(
              const InfiniteListMoreRequested(),
            ),
            itemBuilder: (BuildContext context, int index) {
              final PillarInfo p = filtered[index];
              final bool isMine = p.ownerAddress.toString() == kSelectedAddress;
              final bool isDelegated = delegatedName == p.name;
              final bool isExpanded = _expandedPillarName == p.name;
              final double uptime = p.expectedMomentums > 0
                  ? (p.producedMomentums / p.expectedMomentums) * 100
                  : 0;
              final double weightVal =
                  double.tryParse(p.weight.addDecimals(kZnnCoin.decimals)) ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  InkWell(
                    onTap: () => setState(() {
                      _expandedPillarName = isExpanded ? null : p.name;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 16,
                                  color: tokens.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    p.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isMine) ...<Widget>[
                                  const SizedBox(width: 8),
                                  SyriusStatusBadge(
                                    label: context.l10n.yours,
                                    tone: SyriusBadgeTone.success,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${_compactFormat.format(weightVal)} ZNN',
                              textAlign: TextAlign.right,
                              style: tokens.monoStyle(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${p.giveMomentumRewardPercentage}% / '
                              '${p.giveDelegateRewardPercentage}%',
                              textAlign: TextAlign.right,
                              style: tokens.monoStyle(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${uptime.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: tokens.monoStyle(),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: isDelegated
                                  ? SyriusPillButton(
                                      label: context.l10n.delegated,
                                      compact: true,
                                      onPressed: null,
                                    )
                                  : SyriusPillButton(
                                      label: context.l10n.delegateKey
                                          .capitalize(),
                                      compact: true,
                                      isLoading:
                                          _delegatingPillarName == p.name,
                                      onPressed: canDelegate
                                          ? () {
                                              setState(
                                                () => _delegatingPillarName =
                                                    p.name,
                                              );
                                              context
                                                  .read<DelegationBloc>()
                                                  .add(
                                                    DelegationRequested(
                                                      address: Address.parse(
                                                        kSelectedAddress!,
                                                      ),
                                                      pillarName: p.name,
                                                    ),
                                                  );
                                            }
                                          : null,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      color: tokens.surfaceSubtle,
                      padding: const EdgeInsets.fromLTRB(44, 12, 24, 14),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                SyriusKeyValueRow(
                                  label: 'PRODUCER',
                                  value: Row(
                                    children: <Widget>[
                                      Text(
                                        _shorten(p.producerAddress.toString()),
                                        style: tokens.monoStyle(
                                          fontSize: 12.5,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => unawaited(
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: p.producerAddress
                                                  .toString(),
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 13,
                                          color: tokens.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SyriusKeyValueRow(
                                  label: 'REWARD',
                                  value: Text(
                                    _shorten(p.withdrawAddress.toString()),
                                    style: tokens.monoStyle(
                                      fontSize: 12.5,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                SyriusKeyValueRow(
                                  label: 'MOMENTUMS',
                                  value: Text(
                                    '${_intFormat.format(
                                      p.producedMomentums,
                                    )} of '
                                    '${_intFormat.format(
                                      p.expectedMomentums,
                                    )} expected',
                                    style: tokens.monoStyle(fontSize: 12.5),
                                  ),
                                ),
                                SyriusKeyValueRow(
                                  label: 'EXPLORER',
                                  value: InkWell(
                                    onTap: () => unawaited(
                                      NavigationUtils.openUrl(
                                        '${uiPrefs.selectedExplorer}/pillar/${p.ownerAddress}',
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.open_in_new_rounded,
                                          size: 13,
                                          color: tokens.textMuted,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          context.l10n.explorer.toLowerCase(),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSentinelsList(BuildContext context, SyriusThemeTokens tokens) {
    return BlocBuilder<SentinelsBloc, InfiniteListState<SentinelInfo>>(
      builder: (BuildContext context, InfiniteListState<SentinelInfo> state) {
        return switch (state.status) {
          InfiniteListStatus.initial => const SyriusLoadingWidget(),
          InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
          InfiniteListStatus.success => _buildSentinelsTable(
            context,
            tokens,
            state.data ?? const <SentinelInfo>[],
            hasReachedMax: state.hasReachedMax,
          ),
        };
      },
    );
  }

  Widget _buildSentinelsTable(
    BuildContext context,
    SyriusThemeTokens tokens,
    List<SentinelInfo> sentinels, {
    required bool hasReachedMax,
  }) {
    if (sentinels.isEmpty) {
      return SyriusEmptyState(message: context.l10n.noneYet);
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text('OWNER', style: tokens.microLabelStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text('REGISTERED', style: tokens.microLabelStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text('REVOCABLE', style: tokens.microLabelStyle()),
              ),
              const SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('STATUS'),
                ),
              ),
            ],
          ),
        ),
        const SyriusDivider(),
        Expanded(
          child: SyriusPaginatedListView(
            itemCount: sentinels.length,
            hasReachedMax: hasReachedMax,
            isLoadingMore: context
                .read<SentinelsBloc>()
                .isLoadingMoreListenable,
            dataIdentity: sentinels,
            separatorBuilder: (_, _) => const SyriusDivider(),
            onLoadMore: () => context.read<SentinelsBloc>().add(
              const InfiniteListMoreRequested(),
            ),
            itemBuilder: (BuildContext context, int index) {
              final SentinelInfo s = sentinels[index];
              final bool isMine = s.owner.toString() == kSelectedAddress;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              isMine
                                  ? ZenonAddressUtils.getLabel(
                                      s.owner.toString(),
                                    )
                                  : _shorten(s.owner.toString()),
                              overflow: TextOverflow.ellipsis,
                              style: tokens.monoStyle(),
                            ),
                          ),
                          if (isMine) ...<Widget>[
                            const SizedBox(width: 8),
                            SyriusStatusBadge(
                              label: context.l10n.yours,
                              tone: SyriusBadgeTone.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAge(s.registrationTimestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        s.isRevocable
                            ? 'now'
                            : _formatCooldown(s.revokeCooldown),
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: isMine && s.isRevocable
                            ? RevokeSentinelButton(
                                onRevoked: () => context
                                    .read<SentinelsBloc>()
                                    .add(const InfiniteListRefreshRequested()),
                              )
                            : SyriusStatusBadge(
                                label: s.active
                                    ? context.l10n.active
                                    : 'Revoked',
                                tone: s.active
                                    ? SyriusBadgeTone.success
                                    : SyriusBadgeTone.neutral,
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _collectPillarRewards(BuildContext context) {
    setState(() => _collecting = true);
    context.read<SendTransactionBloc>().add(
      SendTransactionInitiateFromBlock(
        block: zenon!.embedded.pillar.collectReward(),
        fromAddress: kSelectedAddress!,
        reasonForGeneratingPlasma: context.l10n.collectPillarRewards,
      ),
    );
  }

  void _collectSentinelRewards(BuildContext context) {
    setState(() => _collecting = true);
    context.read<SendTransactionBloc>().add(
      SendTransactionInitiateFromBlock(
        block: zenon!.embedded.sentinel.collectReward(),
        fromAddress: kSelectedAddress!,
        reasonForGeneratingPlasma: context.l10n.collectSentinelRewards,
      ),
    );
  }

  Future<void> _openSpawnPillar(BuildContext context) async {
    final PillarsBloc pillarsBloc = context.read<PillarsBloc>();
    final PillarsByOwnerBloc pillarsByOwnerBloc = context
        .read<PillarsByOwnerBloc>();
    final String? registeredPillarName = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => StepperScreen(
          breadcrumbParent: context.l10n.nodes,
          title: context.l10n.spawnPillar,
          stepper: const CreatePillarStepperPage(),
          onStepperNotificationSeeMorePressed:
              widget.onStepperNotificationSeeMorePressed,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (registeredPillarName != null && registeredPillarName.isNotEmpty) {
      pillarsBloc.add(const InfiniteListRefreshRequested());
      final String? selected = kSelectedAddress;
      if (selected != null) {
        pillarsByOwnerBloc.add(
          FetchRequestData(address: Address.parse(selected)),
        );
      }
      setState(() {
        _activeSubTab = NodesSubTab.pillars;
        _showMyPillarPanel = true;
        _expandedPillarName = registeredPillarName;
        _searchController.clear();
      });
    }
  }

  void _openSpawnSentinel(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StepperScreen(
          breadcrumbParent: context.l10n.nodes,
          title: '${context.l10n.spawn} ${context.l10n.sentinels}',
          stepper: const CreateSentinelStepperPage(),
          onStepperNotificationSeeMorePressed:
              widget.onStepperNotificationSeeMorePressed,
        ),
      ),
    );
  }

  Future<void> _showRewardsModal(
    BuildContext context, {
    required bool isSentinel,
  }) async {
    final PillarRewardsHistoryBloc? pillarRewardsBloc = isSentinel
        ? null
        : context.read<PillarRewardsHistoryBloc>();
    final SentinelRewardsHistoryBloc? sentinelRewardsBloc = isSentinel
        ? context.read<SentinelRewardsHistoryBloc>()
        : null;

    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 620,
      builder: (_) => SyriusModalShell(
        title: isSentinel
            ? context.l10n.sentinelRewardsTitle
            : context.l10n.pillarRewardsTitle,
        child: SizedBox(
          height: 300,
          child: isSentinel
              ? BlocProvider<SentinelRewardsHistoryBloc>.value(
                  value: sentinelRewardsBloc!,
                  child: const SentinelRewardsCard(),
                )
              : BlocProvider<PillarRewardsHistoryBloc>.value(
                  value: pillarRewardsBloc!,
                  child: const PillarRewardsCard(),
                ),
        ),
      ),
    );
  }

  static String _formatRaw(BigInt raw, int decimals) {
    final String s = raw.addDecimals(decimals);
    final double? n = double.tryParse(s);
    return n != null ? _amountFormat.format(n) : s;
  }

  static String _formatCooldown(int seconds) {
    final int days = seconds ~/ 86400;
    final int hours = (seconds % 86400) ~/ 3600;
    if (days > 0) {
      return 'in $days d $hours h';
    }
    return 'in ${hours > 0 ? hours : 1} h';
  }

  static String _formatAge(int timestampSec) {
    final int diff =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) - timestampSec;
    final int days = diff ~/ 86400;
    if (days >= 365) {
      return '${days ~/ 365} y ago';
    }
    if (days >= 30) {
      return '${days ~/ 30} mo ago';
    }
    return '${days > 0 ? days : 1} d ago';
  }

  static String _shorten(String address) {
    if (address.length <= 14) {
      return address;
    }
    return '${address.substring(0, 6)}...'
        '${address.substring(address.length - 4)}';
  }
}

class _UnderlineTabButton extends StatelessWidget {
  const _UnderlineTabButton({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: active ? tokens.znnGreen : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$count',
                style: tokens.monoStyle(fontSize: 12, color: tokens.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
