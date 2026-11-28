import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Tab content rendering the redesigned Home overview (Screens 01–06).
class DashboardTabChild extends StatefulWidget {
  /// Creates a [DashboardTabChild].
  const DashboardTabChild({super.key, this.changePage});

  /// Optional callback used by dashboard actions to switch active [Tabs].
  final void Function(Tabs)? changePage;

  @override
  State<DashboardTabChild> createState() => _DashboardTabChildState();
}

class _DashboardTabChildState extends State<DashboardTabChild> {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.####');

  bool _allAddressesFilter = true;
  bool _tokensExpanded = false;
  bool _pendingExpanded = true;
  bool _collectingAll = false;

  @override
  Widget build(BuildContext context) {
    final String? selectedAddress = kSelectedAddress;
    final Address? parsed =
        selectedAddress != null && selectedAddress.isNotEmpty
        ? Address.parse(selectedAddress)
        : null;

    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<UncollectedPillarRewardsBloc>(
          create: (_) {
            final UncollectedPillarRewardsBloc bloc =
                UncollectedPillarRewardsBloc(zenon: zenon!);
            if (parsed != null) {
              bloc.add(FetchRequestData(address: parsed));
            }
            return bloc;
          },
        ),
        BlocProvider<UncollectedSentinelRewardsBloc>(
          create: (_) {
            final UncollectedSentinelRewardsBloc bloc =
                UncollectedSentinelRewardsBloc(zenon: zenon!);
            if (parsed != null) {
              bloc.add(FetchRequestData(address: parsed));
            }
            return bloc;
          },
        ),
        BlocProvider<UncollectedStakingRewardsBloc>(
          create: (_) {
            final UncollectedStakingRewardsBloc bloc =
                UncollectedStakingRewardsBloc(zenon: zenon!);
            if (parsed != null) {
              bloc.add(FetchRequestData(address: parsed));
            }
            return bloc;
          },
        ),
      ],
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();
    context.watch<SelectedAddressNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeroBanner(context, uiPrefs),
        const SizedBox(height: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 13, child: _buildActivityCard(context, uiPrefs)),
              const SizedBox(width: 14),
              Expanded(flex: 7, child: _buildRightSidebar(context, uiPrefs)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final String selected = kSelectedAddress ?? '';
    final String addressLabel = selected.isNotEmpty
        ? ZenonAddressUtils.getLabel(selected)
        : context.l10n.addressNumber(1);
    final String shortAddr = _shorten(selected);

    return SyriusHeroBanner(
      child: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (BuildContext context, MultipleBalanceState balState) {
          final AccountInfo? info = balState.data?[selected];
          final BigInt znnRaw = info?.znn() ?? BigInt.zero;
          final BigInt qsrRaw = info?.qsr() ?? BigInt.zero;
          final String znnFormatted = _formatBalance(
            znnRaw,
            kZnnCoin.decimals,
            hidden: uiPrefs.hideBalances,
          );
          final String qsrFormatted = _formatBalance(
            qsrRaw,
            kQsrCoin.decimals,
            hidden: uiPrefs.hideBalances,
          );

          return Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          addressLabel.toUpperCase(),
                          style: tokens.microLabelStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          shortAddr,
                          style: tokens.monoStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _IconMicroButton(
                          icon: Icons.copy_rounded,
                          tooltip: context.l10n.copyAddress,
                          onTap: selected.isEmpty
                              ? null
                              : () {
                                  unawaited(
                                    Clipboard.setData(
                                      ClipboardData(text: selected),
                                    ),
                                  );
                                },
                        ),
                        _buildAddressSwitcher(context, tokens),
                        _IconMicroButton(
                          icon: uiPrefs.hideBalances
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: uiPrefs.hideBalances
                              ? tokens.znnGreen
                              : tokens.textMuted,
                          tooltip: context.l10n.hideBalances,
                          onTap: uiPrefs.toggleHideBalances,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          znnFormatted,
                          style: tokens.monoStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          kZnnCoin.symbol,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.znnGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          qsrFormatted,
                          style: tokens.monoStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          kQsrCoin.symbol,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.qsrBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _buildPlasmaSummary(context, tokens, selected),
              ),
              const SizedBox(width: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  SyriusGradientButton(
                    label: context.l10n.send,
                    icon: Icons.arrow_upward_rounded,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    onPressed: () => _openTransfer(context, TransferMode.send),
                  ),
                  SyriusPillButton(
                    label: context.l10n.receive,
                    icon: Icons.arrow_downward_rounded,
                    height: 38,
                    onPressed: () =>
                        _openTransfer(context, TransferMode.receive),
                  ),
                  SyriusPillButton(
                    label: context.l10n.zap,
                    icon: Icons.bolt_rounded,
                    height: 38,
                    onPressed: () => _openTransfer(context, TransferMode.zap),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressSwitcher(BuildContext context, SyriusThemeTokens tokens) {
    final List<String> addresses = kDefaultAddressList
        .whereType<String>()
        .toList();
    if (addresses.length <= 1) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      tooltip: context.l10n.addresses,
      color: tokens.surface,
      padding: EdgeInsets.zero,
      onSelected: (String addr) => _switchActiveAddress(context, addr),
      itemBuilder: (_) => addresses.map((String addr) {
        final bool isCurrent = addr == kSelectedAddress;
        return PopupMenuItem<String>(
          value: addr,
          child: Row(
            children: <Widget>[
              Icon(
                isCurrent ? Icons.check_circle : Icons.circle_outlined,
                size: 14,
                color: isCurrent ? tokens.znnGreen : tokens.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                ZenonAddressUtils.getLabel(addr),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _shorten(addr),
                style: tokens.monoStyle(
                  fontSize: 11.5,
                  color: tokens.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: tokens.textMuted,
        ),
      ),
    );
  }

  Widget _buildPlasmaSummary(
    BuildContext context,
    SyriusThemeTokens tokens,
    String selectedAddress,
  ) {
    return BlocBuilder<PlasmaStatsBloc, InfiniteListState<PlasmaInfoWrapper>>(
      builder:
          (BuildContext context, InfiniteListState<PlasmaInfoWrapper> state) {
            final List<PlasmaInfoWrapper> entries =
                state.data ?? const <PlasmaInfoWrapper>[];
            PlasmaInfoWrapper? match;
            for (final PlasmaInfoWrapper item in entries) {
              if (item.address == selectedAddress) {
                match = item;
                break;
              }
            }
            match ??= entries.isNotEmpty ? entries.first : null;
            final int currentPlasma = match?.plasmaInfo.currentPlasma ?? 0;
            final int maxPlasma = math.max(
              match?.plasmaInfo.maxPlasma ?? 100000,
              1,
            );
            final double progress = (currentPlasma / maxPlasma).clamp(0.0, 1.0);
            final int estimatedSends = currentPlasma ~/ 21000;
            final String levelLabel = currentPlasma >= 84000
                ? 'HIGH'
                : currentPlasma >= 42000
                ? 'MED'
                : currentPlasma > 0
                ? 'LOW'
                : 'NONE';

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget.changePage?.call(Tabs.plasma),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          context.l10n.plasma.toUpperCase(),
                          style: tokens.microLabelStyle(),
                        ),
                        Text(
                          levelLabel,
                          style: tokens.microLabelStyle(
                            color: currentPlasma > 0
                                ? tokens.textSecondary
                                : tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    SyriusPlasmaBar(progress: progress),
                    const SizedBox(height: 7),
                    Text(
                      context.l10n.enoughForAboutSends(estimatedSends),
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return SyriusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
            child: Row(
              children: <Widget>[
                Text(
                  context.l10n.activity,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const Spacer(),
                SyriusPillButton(
                  label: _allAddressesFilter
                      ? context.l10n.allAddresses
                      : ZenonAddressUtils.getLabel(kSelectedAddress ?? ''),
                  compact: true,
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  onPressed: () {
                    setState(() {
                      _allAddressesFilter = !_allAddressesFilter;
                    });
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  iconSize: 16,
                  splashRadius: 15,
                  color: tokens.textMuted,
                  tooltip: context.l10n.refresh,
                  onPressed: () {
                    if (kSelectedAddress != null) {
                      context.read<LatestTransactionsBloc>().add(
                        InfiniteListRefreshRequested(
                          address: Address.parse(kSelectedAddress!),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const SyriusDivider(),
          Expanded(
            child:
                BlocBuilder<
                  LatestTransactionsBloc,
                  InfiniteListState<AccountBlock>
                >(
                  builder:
                      (
                        BuildContext context,
                        InfiniteListState<AccountBlock> state,
                      ) {
                        final List<AccountBlock> loaded =
                            state.data ?? const <AccountBlock>[];
                        return switch (state.status) {
                          InfiniteListStatus.initial =>
                            const SyriusLoadingWidget(),
                          InfiniteListStatus.failure when loaded.isEmpty =>
                            SyriusErrorWidget(state.error!),
                          InfiniteListStatus.failure ||
                          InfiniteListStatus.success => _buildActivityList(
                            context,
                            tokens,
                            uiPrefs,
                            loaded,
                            hasReachedMax: state.hasReachedMax,
                            hasLoadMoreError:
                                state.status == InfiniteListStatus.failure,
                          ),
                        };
                      },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
    List<AccountBlock> blocks, {
    required bool hasReachedMax,
    bool hasLoadMoreError = false,
  }) {
    if (blocks.isEmpty) {
      return SyriusEmptyState(message: context.l10n.noneYet);
    }

    return SyriusPaginatedListView(
      itemCount: blocks.length,
      hasReachedMax: hasReachedMax,
      hasLoadMoreError: hasLoadMoreError,
      isLoadingMore: context
          .read<LatestTransactionsBloc>()
          .isLoadingMoreListenable,
      dataIdentity: blocks,
      separatorBuilder: (_, _) => const SyriusDivider(),
      onLoadMore: () {
        final String? addr = kSelectedAddress;
        if (addr != null) {
          context.read<LatestTransactionsBloc>().add(
            InfiniteListMoreRequested(address: Address.parse(addr)),
          );
        }
      },
      itemBuilder: (BuildContext context, int index) {
        return _buildActivityRow(context, tokens, uiPrefs, blocks[index]);
      },
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
    AccountBlock txBlock,
  ) {
    final bool isReceive = BlockUtils.isReceiveBlock(txBlock.blockType);
    final AccountBlock info = (isReceive && txBlock.pairedAccountBlock != null)
        ? txBlock.pairedAccountBlock!
        : txBlock;

    final String? zapMessage = _tryExtractZapMessage(info.data);
    final _ActivityMeta meta = _classifyActivity(
      context,
      tokens,
      info: info,
      isReceive: isReceive,
      hasZapMessage: zapMessage != null,
    );

    final Address counterparty = isReceive ? info.address : info.toAddress;
    final String cpString = counterparty.toString();
    final String? contactLabel =
        uiPrefs.contactLabelFor(cpString) ??
        (kAddressLabelMap.containsKey(cpString)
            ? kAddressLabelMap[cpString]
            : null);

    final String symbol = info.token?.symbol ?? kZnnCoin.symbol;
    final int decimals = info.token?.decimals ?? kZnnCoin.decimals;
    final String sign = info.amount == BigInt.zero
        ? ''
        : isReceive
        ? '+ '
        : '- ';
    final String amountText = uiPrefs.hideBalances
        ? '•••• $symbol'
        : '$sign${_formatRawAmount(info.amount, decimals)} $symbol';

    final int tsMs = info.confirmationTimestampMs;
    final String timeAgo = _formatRelativeTime(tsMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Row(
              children: <Widget>[
                Icon(meta.icon, size: 15, color: meta.color),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    meta.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: meta.tintLabel ? meta.color : tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                if (contactLabel != null) ...<Widget>[
                  Text(
                    contactLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    meta.subtitle ?? _shorten(cpString),
                    overflow: TextOverflow.ellipsis,
                    style: tokens.monoStyle(
                      fontSize: 12.5,
                      color: contactLabel != null
                          ? tokens.textMuted
                          : tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            style: tokens.monoStyle(
              fontWeight: FontWeight.w500,
              color: info.amount == BigInt.zero
                  ? tokens.textMuted
                  : tokens.textPrimary,
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              timeAgo,
              textAlign: TextAlign.right,
              style: tokens.monoStyle(fontSize: 12, color: tokens.textMuted),
            ),
          ),
          const SizedBox(width: 14),
          if (zapMessage != null)
            SyriusPillButton(
              label: context.l10n.message,
              compact: true,
              height: 26,
              onPressed: () => _showZapMessageModal(
                context,
                fromAddress: info.address.toString(),
                amountDisplay:
                    '${_formatRawAmount(info.amount, decimals)} $symbol',
                message: zapMessage,
              ),
            )
          else
            _IconMicroButton(
              icon: Icons.open_in_new_rounded,
              tooltip: context.l10n.explorer,
              onTap: () {
                final String base = uiPrefs.selectedExplorer;
                unawaited(
                  NavigationUtils.openUrl('$base/transaction/${info.hash}'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildToCollectCard(context, uiPrefs),
          const SizedBox(height: 12),
          _buildTokensAccordionCard(context, uiPrefs),
          const SizedBox(height: 12),
          _buildPendingAccordionCard(context, uiPrefs),
        ],
      ),
    );
  }

  Widget _buildToCollectCard(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final FetchState<UncollectedReward> pillarState = context
        .watch<UncollectedPillarRewardsBloc>()
        .state;
    final FetchState<UncollectedReward> sentinelState = context
        .watch<UncollectedSentinelRewardsBloc>()
        .state;
    final FetchState<UncollectedReward> stakeState = context
        .watch<UncollectedStakingRewardsBloc>()
        .state;

    BigInt totalZnn = BigInt.zero;
    BigInt totalQsr = BigInt.zero;
    bool hasPillar = false;
    bool hasSentinel = false;
    bool hasStaking = false;

    if (pillarState is FetchPopulated<UncollectedReward>) {
      totalZnn += pillarState.data.znnAmount;
      totalQsr += pillarState.data.qsrAmount;
      hasPillar =
          pillarState.data.znnAmount > BigInt.zero ||
          pillarState.data.qsrAmount > BigInt.zero;
    }
    if (sentinelState is FetchPopulated<UncollectedReward>) {
      totalZnn += sentinelState.data.znnAmount;
      totalQsr += sentinelState.data.qsrAmount;
      hasSentinel =
          sentinelState.data.znnAmount > BigInt.zero ||
          sentinelState.data.qsrAmount > BigInt.zero;
    }
    if (stakeState is FetchPopulated<UncollectedReward>) {
      totalZnn += stakeState.data.znnAmount;
      totalQsr += stakeState.data.qsrAmount;
      hasStaking =
          stakeState.data.znnAmount > BigInt.zero ||
          stakeState.data.qsrAmount > BigInt.zero;
    }

    final bool hasAny = hasPillar || hasSentinel || hasStaking;
    final String znnStr = uiPrefs.hideBalances
        ? '••••'
        : _formatRawAmount(totalZnn, kZnnCoin.decimals);
    final String qsrStr = uiPrefs.hideBalances
        ? '••••'
        : _formatRawAmount(totalQsr, kQsrCoin.decimals);

    return SyriusCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Text(
            context.l10n.toCollect,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$znnStr ZNN · $qsrStr QSR',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: tokens.monoStyle(
                fontSize: 12,
                color: hasAny ? tokens.textPrimary : tokens.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SyriusPillButton(
            label: context.l10n.collectAll,
            compact: true,
            isLoading: _collectingAll,
            onPressed: hasAny
                ? () => _collectAllRewards(
                    context,
                    hasPillar: hasPillar,
                    hasSentinel: hasSentinel,
                    hasStaking: hasStaking,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _collectAllRewards(
    BuildContext context, {
    required bool hasPillar,
    required bool hasSentinel,
    required bool hasStaking,
  }) async {
    final String? address = kSelectedAddress;
    if (_collectingAll || address == null) {
      return;
    }
    setState(() => _collectingAll = true);
    final SendTransactionBloc txBloc = SendTransactionBloc();
    final List<(AccountBlockTemplate, String)> requests =
        <(AccountBlockTemplate, String)>[
          if (hasPillar)
            (
              zenon!.embedded.pillar.collectReward(),
              context.l10n.collectPillarRewards,
            ),
          if (hasSentinel)
            (
              zenon!.embedded.sentinel.collectReward(),
              context.l10n.collectSentinelRewards,
            ),
          if (hasStaking)
            (
              zenon!.embedded.stake.collectReward(),
              context.l10n.collectStakingRewards,
            ),
        ];

    try {
      for (final (AccountBlockTemplate block, String reason) in requests) {
        final Future<SendTransactionState> resultFuture = txBloc.stream
            .firstWhere(
              (SendTransactionState s) =>
                  s.status == SendTransactionStatus.success ||
                  s.status == SendTransactionStatus.failure,
            );
        txBloc.add(
          SendTransactionInitiateFromBlock(
            block: block,
            fromAddress: address,
            reasonForGeneratingPlasma: reason,
          ),
        );
        final SendTransactionState result = await resultFuture;
        if (result.status == SendTransactionStatus.failure &&
            result.error != null) {
          await NotificationUtils.sendNotificationError(result.error!, reason);
          break;
        }
      }
      if (mounted && context.mounted) {
        final Address parsed = Address.parse(address);
        if (hasPillar) {
          context.read<UncollectedPillarRewardsBloc>().add(
            FetchRequestData(address: parsed),
          );
        }
        if (hasSentinel) {
          context.read<UncollectedSentinelRewardsBloc>().add(
            FetchRequestData(address: parsed),
          );
        }
        if (hasStaking) {
          context.read<UncollectedStakingRewardsBloc>().add(
            FetchRequestData(address: parsed),
          );
        }
      }
    } finally {
      await txBloc.close();
      if (mounted) {
        setState(() => _collectingAll = false);
      }
    }
  }

  Widget _buildTokensAccordionCard(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
      builder: (BuildContext context, MultipleBalanceState state) {
        final AccountInfo? info = state.data?[kSelectedAddress];
        final List<BalanceInfoListItem> heldZts =
            (info?.balanceInfoList ?? const <BalanceInfoListItem>[])
                .where(
                  (BalanceInfoListItem item) =>
                      item.token != null &&
                      item.balance != null &&
                      item.balance! > BigInt.zero &&
                      item.token!.tokenStandard != kZnnCoin.tokenStandard &&
                      item.token!.tokenStandard != kQsrCoin.tokenStandard,
                )
                .toList();

        return SyriusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: () => setState(() => _tokensExpanded = !_tokensExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        context.l10n.tokens,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${heldZts.length}',
                        style: tokens.monoStyle(
                          fontSize: 12,
                          color: tokens.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _tokensExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.chevron_right_rounded,
                        size: 17,
                        color: tokens.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (_tokensExpanded) ...<Widget>[
                const SyriusDivider(),
                if (heldZts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.l10n.noneYet,
                      style: TextStyle(fontSize: 12.5, color: tokens.textMuted),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: heldZts.map((BalanceInfoListItem item) {
                        final Token token = item.token!;
                        final String amt = uiPrefs.hideBalances
                            ? '••••'
                            : _formatRawAmount(item.balance!, token.decimals);
                        return InkWell(
                          onTap: () => widget.changePage?.call(Tabs.tokens),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: <Widget>[
                                SyriusTokenAvatar(
                                  symbol: token.symbol,
                                  color: ColorUtils.getTokenColor(
                                    token.tokenStandard,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    token.symbol,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  amt,
                                  style: tokens.monoStyle(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingAccordionCard(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return BlocBuilder<
      PendingTransactionsBloc,
      InfiniteListState<AccountBlock>
    >(
      builder: (BuildContext context, InfiniteListState<AccountBlock> state) {
        final List<AccountBlock> pending = state.data ?? const <AccountBlock>[];
        return SyriusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: () =>
                    setState(() => _pendingExpanded = !_pendingExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        context.l10n.pending,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pending.length}',
                        style: tokens.monoStyle(
                          fontSize: 12,
                          color: tokens.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _pendingExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.chevron_right_rounded,
                        size: 17,
                        color: tokens.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (_pendingExpanded) ...<Widget>[
                const SyriusDivider(),
                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.l10n.noneYet,
                      style: TextStyle(fontSize: 12.5, color: tokens.textMuted),
                    ),
                  )
                else
                  Column(
                    children: pending.take(5).map((AccountBlock block) {
                      final String sym = block.token?.symbol ?? kZnnCoin.symbol;
                      final int dec =
                          block.token?.decimals ?? kZnnCoin.decimals;
                      final String amt = uiPrefs.hideBalances
                          ? '•••• $sym'
                          : '${_formatRawAmount(block.amount, dec)} $sym';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 14,
                              color: tokens.znnGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.l10n.receive} $amt',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            SyriusStatusBadge(
                              label: context.l10n.momentum,
                              tone: SyriusBadgeTone.info,
                              icon: Icons.schedule_rounded,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showZapMessageModal(
    BuildContext context, {
    required String fromAddress,
    required String amountDisplay,
    required String message,
  }) async {
    final SyriusThemeTokens tokens = context.syriusTheme;
    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 460,
      builder: (BuildContext dialogContext) {
        return SyriusModalShell(
          title: context.l10n.zap,
          leadingIcon: Icons.bolt_rounded,
          leadingIconColor: tokens.ztsMagenta,
          actions: <Widget>[
            SyriusPillButton(
              label: context.l10n.zapBack,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openTransfer(
                  context,
                  TransferMode.zap,
                  recipientAddress: fromAddress,
                );
              },
            ),
            SyriusGradientButton(
              label: context.l10n.nice,
              height: 36,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SyriusKeyValueRow(
                label: context.l10n.from,
                value: Text(
                  fromAddress,
                  style: tokens.monoStyle(
                    fontSize: 12.5,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              SyriusKeyValueRow(
                label: context.l10n.amount,
                value: Text(
                  amountDisplay,
                  style: tokens.monoStyle(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(Icons.info_outline, size: 14, color: tokens.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.writtenBySenderNotSyrius,
                      style: TextStyle(fontSize: 12, color: tokens.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTransfer(
    BuildContext context,
    TransferMode mode, {
    String? recipientAddress,
  }) {
    final ShellNavigationController? nav =
        Provider.of<ShellNavigationController?>(context, listen: false);
    nav?.requestTransfer(mode: mode, recipientAddress: recipientAddress);
    widget.changePage?.call(Tabs.transfer);
  }

  void _switchActiveAddress(BuildContext context, String newAddress) {
    if (kSelectedAddress == newAddress) {
      return;
    }
    Provider.of<SelectedAddressNotifier>(
      context,
      listen: false,
    ).changeSelectedAddress(newAddress);
    context.read<PlasmaBeneficiaryAddressCubit>().changeAddress(newAddress);
    final Address parsed = Address.parse(newAddress);
    context.read<LatestTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: parsed),
    );
    context.read<PendingTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: parsed),
    );
    context.read<UncollectedPillarRewardsBloc>().add(
      FetchRequestData(address: parsed),
    );
    context.read<UncollectedSentinelRewardsBloc>().add(
      FetchRequestData(address: parsed),
    );
    context.read<UncollectedStakingRewardsBloc>().add(
      FetchRequestData(address: parsed),
    );
  }

  _ActivityMeta _classifyActivity(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required AccountBlock info,
    required bool isReceive,
    required bool hasZapMessage,
  }) {
    if (hasZapMessage) {
      return _ActivityMeta(
        label: context.l10n.zap,
        icon: Icons.bolt_rounded,
        color: tokens.znnGreen,
        tintLabel: true,
      );
    }
    final Address target = info.toAddress;
    if (target == plasmaAddress) {
      return _ActivityMeta(
        label: context.l10n.fused,
        icon: Icons.bolt_outlined,
        color: tokens.textSecondary,
        subtitle: context.l10n.plasma,
      );
    }
    if (target == stakeAddress) {
      return _ActivityMeta(
        label: context.l10n.staked,
        icon: Icons.donut_large_outlined,
        color: tokens.textSecondary,
      );
    }
    if (target == pillarAddress) {
      return _ActivityMeta(
        label: isReceive ? context.l10n.rewards : context.l10n.delegated,
        icon: Icons.layers_outlined,
        color: isReceive ? tokens.znnGreen : tokens.textSecondary,
        tintLabel: isReceive,
      );
    }
    if (isReceive) {
      return _ActivityMeta(
        label: context.l10n.received,
        icon: Icons.arrow_downward_rounded,
        color: tokens.znnGreen,
        tintLabel: true,
      );
    }
    return _ActivityMeta(
      label: context.l10n.sent,
      icon: Icons.arrow_upward_rounded,
      color: tokens.textSecondary,
    );
  }

  static String? _tryExtractZapMessage(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    try {
      final String decoded = utf8.decode(data, allowMalformed: false).trim();
      if (decoded.isEmpty || decoded.length > 200) {
        return null;
      }
      // Require printable ASCII/Unicode text (exclude ABI binary calls).
      final bool printable = decoded.runes.every(
        (int r) => r == 10 || r == 13 || r >= 32,
      );
      return printable ? decoded : null;
    } on Object catch (_) {
      return null;
    }
  }

  static String _formatBalance(
    BigInt raw,
    int decimals, {
    required bool hidden,
  }) {
    if (hidden) {
      return '• • • •';
    }
    return _formatRawAmount(raw, decimals);
  }

  static String _formatRawAmount(BigInt raw, int decimals) {
    final String decimalStr = raw.addDecimals(decimals);
    final double? parsed = double.tryParse(decimalStr);
    if (parsed == null) {
      return decimalStr;
    }
    return _amountFormat.format(parsed);
  }

  static String _shorten(String address) {
    if (address.length <= 14) {
      return address;
    }
    return '${address.substring(0, 6)}...'
        '${address.substring(address.length - 4)}';
  }

  static String _formatRelativeTime(int? timestampMs) {
    if (timestampMs == null) {
      return '';
    }
    final Duration diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} h';
    }
    return '${diff.inDays} d';
  }
}

class _ActivityMeta {
  const _ActivityMeta({
    required this.label,
    required this.icon,
    required this.color,
    this.tintLabel = false,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool tintLabel;
  final String? subtitle;
}

class _IconMicroButton extends StatelessWidget {
  const _IconMicroButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 14,
            color: color ?? context.syriusTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
