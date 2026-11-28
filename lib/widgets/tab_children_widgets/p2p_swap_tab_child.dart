import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

enum _SwapFilter { all, active, completed, reclaimable }

/// Redesigned P2P Swap screen matching mockup Screen 26.
class P2pSwapTabChild extends StatefulWidget {
  /// Creates a [P2pSwapTabChild].
  const P2pSwapTabChild({super.key});

  @override
  State<P2pSwapTabChild> createState() => _P2pSwapTabChildState();
}

class _P2pSwapTabChildState extends State<P2pSwapTabChild> {
  bool _hasCheckedLocalTime = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasCheckedLocalTime) {
      return;
    }
    _hasCheckedLocalTime = true;
    unawaited(
      NodeUtils.checkForLocalTimeDiscrepancy(
        context.l10n.localTimeDiscrepancyDetected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HtlcSwapRepository swapRepository = sl<HtlcSwapRepository>();
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<StartP2pSwapBloc>(
          create: (_) => StartP2pSwapBloc(
            accountBlockUtils: AccountBlockUtils(
              publishSuccessNotification: false,
            ),
            swapRepository: swapRepository,
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<P2pSwapsCubit>(
          create: (_) => P2pSwapsCubit(swapRepository: swapRepository),
        ),
      ],
      child: const _P2pSwapWorkspaceView(),
    );
  }
}

class _P2pSwapWorkspaceView extends StatefulWidget {
  const _P2pSwapWorkspaceView();

  @override
  State<_P2pSwapWorkspaceView> createState() => _P2pSwapWorkspaceViewState();
}

class _P2pSwapWorkspaceViewState extends State<_P2pSwapWorkspaceView> {
  _SwapFilter _filter = _SwapFilter.all;
  String? _expandedSwapId;

  Future<bool> _confirmUserWarningIfNeeded(BuildContext context) async {
    final bool hasReadWarning =
        sharedPrefsService?.get(
              kHasReadP2pSwapWarningKey,
              defaultValue: kHasReadP2pSwapWarningDefaultValue,
            )
            as bool? ??
        true;

    if (hasReadWarning) {
      return true;
    }

    final bool? result = await showCustomDialog<bool>(
      context: context,
      content: const P2pSwapWarningModal(),
    );

    if (result == true) {
      await sharedPrefsService?.put(kHasReadP2pSwapWarningKey, true);
      return true;
    }

    return false;
  }

  Future<void> _onStartSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);
    if (!canContinue || !context.mounted) {
      return;
    }
    unawaited(
      showCustomDialog<void>(
        context: context,
        content: BlocProvider<StartP2pSwapBloc>.value(
          value: context.read<StartP2pSwapBloc>(),
          child: const StartP2pSwapModal(),
        ),
      ),
    );
  }

  Future<void> _onJoinSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);
    if (!canContinue || !context.mounted) {
      return;
    }

    final String? swapId = await showCustomDialog<String>(
      context: context,
      content: const JoinP2pSwapModal(),
    );

    if (swapId == null || !context.mounted) {
      return;
    }

    _openSwapDetailsModal(context, swapId);
    unawaited(
      NotificationUtils.showForegroundNotification(
        context,
        WalletNotification(
          title: context.l10n.swapJoined,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: context.l10n.hashValue(swapId),
          type: NotificationType.paymentSent,
        ),
      ),
    );
  }

  void _openSwapDetailsModal(BuildContext context, String swapId) {
    unawaited(
      showCustomDialog<void>(
        context: context,
        content: P2pSwapModal(swapId: swapId),
      ),
    );
  }

  void _onStartSwapStateChanged(BuildContext context, StartP2pSwapState state) {
    if (state is StartP2pSwapDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          setState(() => _expandedSwapId = state.swap.id);
          unawaited(
            NotificationUtils.showForegroundNotification(
              context,
              WalletNotification(
                title: context.l10n.swapStarted,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details: context.l10n.hashValue(state.swap.initialHtlcId),
                type: NotificationType.paymentSent,
              ),
            ),
          );
        }
      });
    } else if (state case StartP2pSwapFailure(
      :final SyriusException exception,
    )) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorStartingSwap,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return BlocListener<StartP2pSwapBloc, StartP2pSwapState>(
      listener: _onStartSwapStateChanged,
      child: BlocBuilder<PowGeneratingStatusBloc, PowGeneratingStatusState>(
        bloc: sl.get<PowGeneratingStatusBloc>(),
        builder: (_, PowGeneratingStatusState powState) {
          final bool isGeneratingPlasma = powState.isGenerating;
          return BlocBuilder<P2pSwapsCubit, P2pSwapsState>(
            builder: (BuildContext context, P2pSwapsState swapsState) {
              final List<P2pSwap> allSwaps = switch (swapsState) {
                P2pSwapsPopulated(:final List<P2pSwap> swaps) => swaps,
                _ => const <P2pSwap>[],
              };

              final int activeCount = allSwaps
                  .where(
                    (P2pSwap s) =>
                        s.state == P2pSwapState.active ||
                        s.state == P2pSwapState.pending,
                  )
                  .length;
              final int completedCount = allSwaps
                  .where((P2pSwap s) => s.state == P2pSwapState.completed)
                  .length;
              final int reclaimCount = allSwaps
                  .where((P2pSwap s) => s.state == P2pSwapState.reclaimable)
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildTopBar(
                    context,
                    tokens,
                    activeCount: activeCount,
                    completedCount: completedCount,
                    reclaimCount: reclaimCount,
                    isGeneratingPlasma: isGeneratingPlasma,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildSwapsTableCard(
                      context,
                      tokens,
                      uiPrefs,
                      swapsState,
                      allSwaps,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required int activeCount,
    required int completedCount,
    required int reclaimCount,
    required bool isGeneratingPlasma,
  }) {
    return SyriusCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          SyriusMetricBlock(label: context.l10n.active, value: '$activeCount'),
          const SizedBox(width: 28),
          SyriusMetricBlock(
            label: context.l10n.completed,
            value: '$completedCount',
          ),
          const SizedBox(width: 28),
          SyriusMetricBlock(
            label: context.l10n.toReclaim,
            value: '$reclaimCount',
          ),
          const Spacer(),
          SyriusPillButton(
            label: context.l10n.joinSwap,
            icon: Icons.link,
            onPressed: () {
              if (isGeneratingPlasma) {
                ToastUtils.showToast(
                  context,
                  context.l10n.p2pSwapGeneratingPlasma,
                );
                return;
              }
              unawaited(_onJoinSwapPressed(context));
            },
          ),
          const SizedBox(width: 10),
          SyriusGradientButton(
            label: context.l10n.startSwap,
            icon: Icons.add,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onPressed: () {
              if (isGeneratingPlasma) {
                ToastUtils.showToast(
                  context,
                  context.l10n.p2pSwapGeneratingPlasma,
                );
                return;
              }
              unawaited(_onStartSwapPressed(context));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwapsTableCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
    P2pSwapsState state,
    List<P2pSwap> allSwaps,
  ) {
    final List<P2pSwap> visible = _applyFilter(allSwaps);

    return SyriusCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
            child: Row(
              children: <Widget>[
                Text(
                  context.l10n.swaps,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${visible.length}',
                  style: tokens.monoStyle(
                    color: tokens.textMuted,
                  ),
                ),
                const Spacer(),
                _buildFilterDropdown(context, tokens),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  tooltip: context.l10n.options,
                  icon: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                  onSelected: (String action) {
                    if (action == 'reclaim') {
                      unawaited(
                        showCustomDialog<void>(
                          context: context,
                          content: const ReclaimDepositModal(),
                        ),
                      );
                    } else if (action == 'tutorial') {
                      unawaited(NavigationUtils.openUrl(kP2pSwapTutorialLink));
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'reclaim',
                          child: Text(context.l10n.reclaimDeposit),
                        ),
                        PopupMenuItem<String>(
                          value: 'tutorial',
                          child: Text(context.l10n.howItWorks),
                        ),
                      ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 126,
                  child: Text(
                    context.l10n.status.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.youSend.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.youReceive.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.counterparty.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    context.l10n.expires.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: switch (state) {
              P2pSwapsLoading() => const SyriusLoadingWidget(),
              P2pSwapsFailure(:final SyriusException exception) =>
                SyriusErrorWidget(exception),
              P2pSwapsPopulated() when visible.isEmpty => SyriusEmptyState(
                message: context.l10n.noSwapsYet,
              ),
              P2pSwapsPopulated() => ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: tokens.border),
                itemBuilder: (BuildContext context, int index) {
                  final P2pSwap swap = visible[index];
                  final bool expanded = _expandedSwapId == swap.id;
                  return _SwapExpandableRow(
                    key: ValueKey<String>(swap.id),
                    swap: swap,
                    uiPrefs: uiPrefs,
                    expanded: expanded,
                    onToggle: () {
                      setState(() {
                        _expandedSwapId = expanded ? null : swap.id;
                      });
                    },
                    onOpenDetails: () =>
                        _openSwapDetailsModal(context, swap.id),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, SyriusThemeTokens tokens) {
    final String label = switch (_filter) {
      _SwapFilter.all => context.l10n.all,
      _SwapFilter.active => context.l10n.active,
      _SwapFilter.completed => context.l10n.completed,
      _SwapFilter.reclaimable => context.l10n.toReclaim,
    };

    return PopupMenuButton<_SwapFilter>(
      initialValue: _filter,
      onSelected: (_SwapFilter value) => setState(() => _filter = value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_SwapFilter>>[
        PopupMenuItem<_SwapFilter>(
          value: _SwapFilter.all,
          child: Text(context.l10n.all),
        ),
        PopupMenuItem<_SwapFilter>(
          value: _SwapFilter.active,
          child: Text(context.l10n.active),
        ),
        PopupMenuItem<_SwapFilter>(
          value: _SwapFilter.completed,
          child: Text(context.l10n.completed),
        ),
        PopupMenuItem<_SwapFilter>(
          value: _SwapFilter.reclaimable,
          child: Text(context.l10n.toReclaim),
        ),
      ],
      child: Container(
        height: 30,
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
              label,
              style: TextStyle(fontSize: 12.5, color: tokens.textPrimary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 15, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }

  List<P2pSwap> _applyFilter(List<P2pSwap> swaps) {
    return switch (_filter) {
      _SwapFilter.all => swaps,
      _SwapFilter.active =>
        swaps
            .where(
              (P2pSwap s) =>
                  s.state == P2pSwapState.active ||
                  s.state == P2pSwapState.pending,
            )
            .toList(),
      _SwapFilter.completed =>
        swaps.where((P2pSwap s) => s.state == P2pSwapState.completed).toList(),
      _SwapFilter.reclaimable =>
        swaps
            .where((P2pSwap s) => s.state == P2pSwapState.reclaimable)
            .toList(),
    };
  }
}

class _SwapExpandableRow extends StatelessWidget {
  const _SwapExpandableRow({
    required this.swap,
    required this.uiPrefs,
    required this.expanded,
    required this.onToggle,
    required this.onOpenDetails,
    super.key,
  });

  final P2pSwap swap;
  final AppUiPreferencesNotifier uiPrefs;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetails;

  String _shortHash(String value) {
    if (value.length <= 14) {
      return value;
    }
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
  }

  String _counterpartyDisplay(String address) {
    final String? contact = uiPrefs.contactLabelFor(address);
    if (contact != null) {
      return contact;
    }
    final String? own = kAddressLabelMap[address];
    if (own != null) {
      return own;
    }
    return _shortHash(address);
  }

  String _formatTiming(P2pSwap s) {
    final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (s.state == P2pSwapState.active || s.state == P2pSwapState.pending) {
      final HtlcSwap htlc = s as HtlcSwap;
      final int remaining = htlc.initialHtlcExpirationTime - nowSec;
      if (remaining <= 0) {
        return '0 m';
      }
      final int hours = remaining ~/ 3600;
      final int mins = (remaining % 3600) ~/ 60;
      return '$hours h $mins m';
    }
    final int elapsed = (nowSec - s.startTime).clamp(0, 1 << 30);
    if (elapsed < 3600) {
      return '${(elapsed ~/ 60).clamp(1, 59)} min ago';
    }
    if (elapsed < 86400) {
      return '${elapsed ~/ 3600} h ago';
    }
    return '${elapsed ~/ 86400} d ago';
  }

  SyriusStatusBadge _buildBadge(BuildContext context) {
    return switch (swap.state) {
      P2pSwapState.pending || P2pSwapState.active => SyriusStatusBadge(
        label: context.l10n.waiting,
        tone: SyriusBadgeTone.info,
        leadingDot: true,
      ),
      P2pSwapState.completed => SyriusStatusBadge(
        label: context.l10n.completed,
        tone: SyriusBadgeTone.success,
        icon: Icons.check,
      ),
      P2pSwapState.reclaimable => SyriusStatusBadge(
        label: context.l10n.toReclaim,
        tone: SyriusBadgeTone.warning,
      ),
      P2pSwapState.unsuccessful => SyriusStatusBadge(
        label: context.l10n.reclaimed,
      ),
      P2pSwapState.error => SyriusStatusBadge(
        label: context.l10n.error,
        tone: SyriusBadgeTone.error,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final String sendText = uiPrefs.hideBalances
        ? '•••• ${swap.fromToken.symbol}'
        : '${swap.fromAmount.addDecimals(swap.fromToken.decimals)} '
              '${swap.fromToken.symbol}';
    final String receiveText = swap.toAmount != null && swap.toToken != null
        ? (uiPrefs.hideBalances
              ? '•••• ${swap.toToken!.symbol}'
              : '${swap.toAmount!.addDecimals(swap.toToken!.decimals)} '
                    '${swap.toToken!.symbol}')
        : '—';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      color: expanded
          ? tokens.surfaceElevated.withValues(alpha: 0.45)
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 126,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildBadge(context),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      sendText,
                      style: tokens.monoStyle(
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      receiveText,
                      style: tokens.monoStyle(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _counterpartyDisplay(swap.counterpartyAddress),
                      overflow: TextOverflow.ellipsis,
                      style: tokens.monoStyle(
                        fontSize: 12.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      _formatTiming(swap),
                      style: tokens.monoStyle(
                        fontSize: 12,
                        color: tokens.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) _buildExpandedPanel(context, tokens),
        ],
      ),
    );
  }

  Widget _buildExpandedPanel(BuildContext context, SyriusThemeTokens tokens) {
    final HtlcSwap htlc = swap as HtlcSwap;
    final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int elapsed = (nowSec - swap.startTime).clamp(0, 1 << 30);
    final String startedLabel = elapsed < 3600
        ? '${(elapsed ~/ 60).clamp(1, 59)} min ago'
        : elapsed < 86400
        ? '${elapsed ~/ 3600} h ago'
        : '${elapsed ~/ 86400} d ago';
    final bool isWaiting =
        swap.state == P2pSwapState.active || swap.state == P2pSwapState.pending;
    final String explorerUrl =
        '${uiPrefs.selectedExplorer}transaction/${htlc.initialHtlcId}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isWaiting) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.waitingForCounterpartyKeepSyriusOpen,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _formatTiming(swap),
                    style: tokens.monoStyle(
                      fontSize: 12,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    SyriusKeyValueRow(
                      label: context.l10n.yourDepositId,
                      labelWidth: 118,
                      value: Row(
                        children: <Widget>[
                          Text(
                            _shortHash(htlc.initialHtlcId),
                            style: tokens.monoStyle(
                              fontSize: 12.5,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => ClipboardUtils.copyToClipboard(
                              htlc.initialHtlcId,
                              context,
                            ),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: tokens.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SyriusPillButton(
                            label: context.l10n.copyForThem,
                            compact: true,
                            height: 26,
                            onPressed: () => ClipboardUtils.copyToClipboard(
                              htlc.initialHtlcId,
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (swap.toAmount != null && swap.toToken != null)
                      SyriusKeyValueRow(
                        label: context.l10n.rate,
                        labelWidth: 118,
                        value: ExchangeRate(
                          fromAmount: swap.fromAmount,
                          fromToken: swap.fromToken,
                          toAmount: swap.toAmount!,
                          toToken: swap.toToken!,
                        ),
                      ),
                    SyriusKeyValueRow(
                      label: context.l10n.started,
                      labelWidth: 118,
                      value: Row(
                        children: <Widget>[
                          Text(
                            startedLabel,
                            style: tokens.monoStyle(
                              fontSize: 12.5,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () =>
                                unawaited(NavigationUtils.openUrl(explorerUrl)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: tokens.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.explorer.toLowerCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: <Widget>[
                    SyriusKeyValueRow(
                      label: context.l10n.counterparty,
                      labelWidth: 110,
                      value: SelectableText(
                        swap.counterpartyAddress,
                        style: tokens.monoStyle(
                          fontSize: 12,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    SyriusKeyValueRow(
                      label: context.l10n.hashlock,
                      labelWidth: 110,
                      value: Text(
                        _shortHash(htlc.hashLock),
                        style: tokens.monoStyle(
                          fontSize: 12,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    SyriusKeyValueRow(
                      label: context.l10n.secret,
                      labelWidth: 110,
                      value: Text(
                        htlc.preimage != null &&
                                swap.state == P2pSwapState.completed
                            ? _shortHash(htlc.preimage!)
                            : context.l10n.keptOnThisComputerUntilTheyJoin,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              SyriusPillButton(
                label: context.l10n.details,
                compact: true,
                onPressed: onOpenDetails,
              ),
              if (swap.state == P2pSwapState.completed ||
                  swap.state == P2pSwapState.unsuccessful ||
                  swap.state == P2pSwapState.error) ...<Widget>[
                const SizedBox(width: 8),
                DeleteP2pSwapButton(swapId: swap.id),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
