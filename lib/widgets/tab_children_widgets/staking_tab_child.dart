import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Redesigned Staking workspace with top summary metrics, inline stake drawer,
/// and clean stakes table (Screens 13–15).
class StakingTabChild extends StatefulWidget {
  /// Creates a [StakingTabChild].
  const StakingTabChild({super.key});

  @override
  State<StakingTabChild> createState() => _StakingTabChildState();
}

class _StakingTabChildState extends State<StakingTabChild> {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.####');
  static final DateFormat _unlockDateFormat = DateFormat('d MMM yyyy');

  bool _showCreateDrawer = false;
  int _selectedMonths = 6;
  final TextEditingController _amountController = TextEditingController();
  bool _submittingStake = false;
  bool _collecting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Address address = Address.parse(kSelectedAddress!);
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<StakesBloc>(
          create: (_) =>
              StakesBloc(zenon: zenon!)
                ..add(InfiniteListRequested(address: address)),
        ),
        BlocProvider<UncollectedStakingRewardsBloc>(
          create: (_) =>
              UncollectedStakingRewardsBloc(zenon: zenon!)
                ..add(FetchRequestData(address: address)),
        ),
        BlocProvider<SendTransactionBloc>(create: (_) => SendTransactionBloc()),
      ],
      child: Builder(builder: _buildView),
    );
  }

  Widget _buildView(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return BlocListener<SendTransactionBloc, SendTransactionState>(
      listenWhen: (SendTransactionState prev, SendTransactionState curr) =>
          prev.status != curr.status,
      listener: (BuildContext context, SendTransactionState state) {
        if (state.status == SendTransactionStatus.success) {
          setState(() {
            _submittingStake = false;
            _collecting = false;
            _amountController.clear();
            _showCreateDrawer = false;
          });
          final Address addr = Address.parse(kSelectedAddress!);
          context.read<StakesBloc>().add(
            InfiniteListRefreshRequested(address: addr),
          );
          context.read<UncollectedStakingRewardsBloc>().add(
            FetchRequestData(address: addr),
          );
          sl<MultipleBalanceBloc>().add(
            MultipleBalanceFetch(
              addresses: kDefaultAddressList.whereType<String>().toList(),
            ),
          );
        } else if (state.status == SendTransactionStatus.failure) {
          setState(() {
            _submittingStake = false;
            _collecting = false;
          });
          if (state.error != null) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.error!,
                context.l10n.errorWhileGeneratingStake,
              ),
            );
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSummaryBar(context, tokens, uiPrefs),
          if (_showCreateDrawer) ...<Widget>[
            const SizedBox(height: 12),
            _buildCreateStakePanel(context, tokens, uiPrefs),
          ],
          const SizedBox(height: 12),
          Expanded(child: _buildStakesTableCard(context, tokens, uiPrefs)),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return BlocBuilder<StakesBloc, InfiniteListState<StakeEntry>>(
      builder:
          (BuildContext context, InfiniteListState<StakeEntry> stakesState) {
            final List<StakeEntry> stakes =
                stakesState.data ?? const <StakeEntry>[];
            BigInt totalStaked = BigInt.zero;
            for (final StakeEntry entry in stakes) {
              totalStaked += entry.amount;
            }

            final FetchState<UncollectedReward> uncollectedState = context
                .watch<UncollectedStakingRewardsBloc>()
                .state;
            final BigInt uncollectedQsr =
                uncollectedState is FetchPopulated<UncollectedReward>
                ? uncollectedState.data.qsrAmount
                : BigInt.zero;

            final FetchState<RewardHistoryList> historyState = context
                .watch<StakingRewardsHistoryBloc>()
                .state;
            BigInt last7DaysQsr = BigInt.zero;
            if (historyState is FetchPopulated<RewardHistoryList>) {
              for (final RewardHistoryEntry h in historyState.data.list.take(
                7,
              )) {
                last7DaysQsr += h.qsrAmount;
              }
            }

            final String stakedStr = uiPrefs.hideBalances
                ? '••••'
                : _formatRaw(totalStaked, kZnnCoin.decimals);
            final String collectStr = uiPrefs.hideBalances
                ? '••••'
                : _formatRaw(uncollectedQsr, kQsrCoin.decimals);
            final String recentStr = uiPrefs.hideBalances
                ? '••••'
                : '+ ${_formatRaw(last7DaysQsr, kQsrCoin.decimals)}';

            return SyriusCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: <Widget>[
                  SyriusMetricBlock(
                    label: context.l10n.staked,
                    value: stakedStr,
                    valueSuffix: kZnnCoin.symbol,
                    suffixColor: tokens.znnGreen,
                  ),
                  const SizedBox(width: 28),
                  SyriusMetricBlock(
                    label: context.l10n.toCollect,
                    value: collectStr,
                    valueSuffix: kQsrCoin.symbol,
                    suffixColor: tokens.qsrBlue,
                  ),
                  if (last7DaysQsr > BigInt.zero) ...<Widget>[
                    const SizedBox(width: 28),
                    SyriusMetricBlock(
                      label: context.l10n.lastSevenDays,
                      value: recentStr,
                      valueSuffix: kQsrCoin.symbol,
                      suffixColor: tokens.textSecondary,
                    ),
                  ],
                  if (uncollectedQsr > BigInt.zero) ...<Widget>[
                    const SizedBox(width: 20),
                    SyriusPillButton(
                      label: context.l10n.collect,
                      isLoading: _collecting,
                      onPressed: () {
                        setState(() => _collecting = true);
                        context.read<SendTransactionBloc>().add(
                          SendTransactionInitiateFromBlock(
                            block: zenon!.embedded.stake.collectReward(),
                            fromAddress: kSelectedAddress!,
                            reasonForGeneratingPlasma:
                                context.l10n.collectStakingRewards,
                          ),
                        );
                      },
                    ),
                  ],
                  const Spacer(),
                  SyriusGhostButton(
                    label: context.l10n.rewards,
                    icon: Icons.bar_chart_rounded,
                    onPressed: () => _showRewardsHistoryModal(context),
                  ),
                  const SizedBox(width: 10),
                  if (_showCreateDrawer)
                    SyriusPillButton(
                      label: context.l10n.close,
                      icon: Icons.close_rounded,
                      height: 38,
                      onPressed: () =>
                          setState(() => _showCreateDrawer = false),
                    )
                  else
                    SyriusGradientButton(
                      label: context.l10n.stake,
                      icon: Icons.add_rounded,
                      height: 38,
                      onPressed: () => setState(() => _showCreateDrawer = true),
                    ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildCreateStakePanel(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final MultipleBalanceState balState = context
        .watch<MultipleBalanceBloc>()
        .state;
    final BigInt availableZnn =
        balState.data?[kSelectedAddress]?.getBalance(kZnnCoin.tokenStandard) ??
        BigInt.zero;
    final String amountText = _amountController.text.trim();
    final String? amountError = amountText.isNotEmpty
        ? InputValidators.correctValue(
            amountText,
            availableZnn,
            kZnnCoin.decimals,
            stakeMinZnnAmount,
            canBeEqualToMin: true,
            l10n: context.l10n,
          )
        : null;
    final bool valid = amountText.isNotEmpty && amountError == null;
    final DateTime unlockDate = DateTime.now().add(
      Duration(days: _selectedMonths * 30),
    );

    const List<int> durationChoices = <int>[1, 2, 3, 6, 9, 12];

    return SyriusCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.l10n.duration.toUpperCase(),
                style: tokens.microLabelStyle(),
              ),
              const SizedBox(height: 8),
              SyriusSegmentedControl<int>(
                compact: true,
                selected: _selectedMonths,
                onChanged: (int m) => setState(() => _selectedMonths = m),
                options: durationChoices
                    .map(
                      (int m) => SyriusSegmentOption<int>(
                        value: m,
                        label: m == 12 ? '12 months' : '$m',
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.l10n.amount.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('create_stake_amount_field'),
                  controller: _amountController,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _amountController.text,
                  ),
                  style: tokens.monoStyle(
                    fontSize: 15,
                    color: tokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: tokens.surfaceSubtle,
                    hintText: '100',
                    errorText: amountError,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          InkWell(
                            onTap: availableZnn > BigInt.zero
                                ? () => setState(() {
                                    _amountController.text = availableZnn
                                        .addDecimals(kZnnCoin.decimals);
                                  })
                                : null,
                            child: Text(
                              context.l10n.max,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.znnGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'of ${uiPrefs.hideBalances ? '••••' : _formatRaw(
                                  availableZnn,
                                  kZnnCoin.decimals,
                                )} ZNN',
                            style: tokens.monoStyle(
                              fontSize: 12,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.l10n.unlocks.toUpperCase(),
                style: tokens.microLabelStyle(),
              ),
              const SizedBox(height: 14),
              Text(
                _unlockDateFormat.format(unlockDate),
                style: tokens.monoStyle(
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(width: 16),
          KeyedSubtree(
            key: const Key('create_stake_submit_button'),
            child: SyriusGradientButton(
              isLoading: _submittingStake,
              label: amountText.isNotEmpty
                  ? '${context.l10n.stake} $amountText ZNN'
                  : context.l10n.stake,
              onPressed: valid && !_submittingStake
                  ? () {
                      setState(() => _submittingStake = true);
                      final AccountBlockTemplate block = zenon!.embedded.stake
                          .stake(
                            _selectedMonths * stakeTimeUnitSec,
                            amountText.extractDecimals(kZnnCoin.decimals),
                          );
                      context.read<SendTransactionBloc>().add(
                        SendTransactionInitiateFromBlock(
                          block: block,
                          fromAddress: kSelectedAddress!,
                          reasonForGeneratingPlasma: context.l10n.createStake,
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakesTableCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return BlocBuilder<StakesBloc, InfiniteListState<StakeEntry>>(
      builder: (BuildContext context, InfiniteListState<StakeEntry> state) {
        final List<StakeEntry> stakes = state.data ?? const <StakeEntry>[];
        return SyriusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                child: Row(
                  children: <Widget>[
                    Text(
                      context.l10n.stakes,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (stakes.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        '${stakes.length}',
                        style: tokens.monoStyle(
                          fontSize: 12,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      iconSize: 16,
                      splashRadius: 15,
                      color: tokens.textMuted,
                      onPressed: () => context.read<StakesBloc>().add(
                        InfiniteListRefreshRequested(
                          address: Address.parse(kSelectedAddress!),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              const SyriusDivider(),
              Expanded(
                child: switch (state.status) {
                  InfiniteListStatus.initial => const SyriusLoadingWidget(),
                  InfiniteListStatus.failure when stakes.isEmpty =>
                    SyriusErrorWidget(state.error!),
                  InfiniteListStatus.failure || InfiniteListStatus.success =>
                    stakes.isEmpty
                        ? SyriusEmptyState(message: context.l10n.noneYet)
                        : _buildStakesTable(
                            context,
                            tokens,
                            uiPrefs,
                            stakes,
                            hasReachedMax: state.hasReachedMax,
                            hasLoadMoreError:
                                state.status == InfiniteListStatus.failure,
                          ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStakesTable(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
    List<StakeEntry> stakes, {
    required bool hasReachedMax,
    bool hasLoadMoreError = false,
  }) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.amount.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.duration.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.started.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  context.l10n.unlocks.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
              ),
              const SizedBox(width: 150),
            ],
          ),
        ),
        const SyriusDivider(),
        Expanded(
          child: SyriusPaginatedListView(
            itemCount: stakes.length,
            hasReachedMax: hasReachedMax,
            hasLoadMoreError: hasLoadMoreError,
            isLoadingMore: context.read<StakesBloc>().isLoadingMoreListenable,
            dataIdentity: stakes,
            separatorBuilder: (_, _) => const SyriusDivider(),
            onLoadMore: () {
              final String? addr = kSelectedAddress;
              if (addr != null) {
                context.read<StakesBloc>().add(
                  InfiniteListMoreRequested(address: Address.parse(addr)),
                );
              }
            },
            itemBuilder: (BuildContext context, int index) {
              final StakeEntry entry = stakes[index];
              final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final bool unlocked = entry.expirationTimestamp <= nowSec;
              final int durationMonths =
                  ((entry.expirationTimestamp - entry.startTimestamp) ~/
                          (30 * 86400))
                      .clamp(1, 12);
              final String amt = uiPrefs.hideBalances
                  ? '•••• ZNN'
                  : '${_formatRaw(entry.amount, kZnnCoin.decimals)} ZNN';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Text(
                        amt,
                        style: tokens.monoStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$durationMonths '
                        'month${durationMonths == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAge(entry.startTimestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: unlocked
                            ? SyriusStatusBadge(
                                label: context.l10n.unlocked,
                                tone: SyriusBadgeTone.success,
                                icon: Icons.check_rounded,
                              )
                            : SyriusStatusBadge(
                                label: _formatRemaining(
                                  entry.expirationTimestamp - nowSec,
                                ),
                                tone: SyriusBadgeTone.info,
                                icon: Icons.schedule_rounded,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: unlocked
                            ? CancelStakeButton(
                                stakeHash: entry.id,
                                onCancelled: () =>
                                    context.read<StakesBloc>().add(
                                      InfiniteListRefreshRequested(
                                        address: Address.parse(
                                          kSelectedAddress!,
                                        ),
                                      ),
                                    ),
                              )
                            : SyriusPillButton(
                                label: context.l10n.cancel,
                                compact: true,
                                onPressed: null,
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

  Future<void> _showRewardsHistoryModal(BuildContext context) async {
    final StakingRewardsHistoryBloc rewardsBloc = context
        .read<StakingRewardsHistoryBloc>();
    await showSyriusBlurredDialog<void>(
      context: context,
      maxWidth: 620,
      builder: (_) => SyriusModalShell(
        title: context.l10n.stakingRewardsTitle,
        child: SizedBox(
          height: 300,
          child: BlocProvider<StakingRewardsHistoryBloc>.value(
            value: rewardsBloc,
            child: const StakingRewardsCard(),
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

  static String _formatAge(int timestampSec) {
    final int diff =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) - timestampSec;
    if (diff < 3600) {
      return '${(diff ~/ 60).clamp(1, 59)} min ago';
    }
    if (diff < 86400) {
      return '${diff ~/ 3600} h ago';
    }
    final int days = diff ~/ 86400;
    if (days >= 30) {
      return '${days ~/ 30} mo ago';
    }
    return '$days d ago';
  }

  static String _formatRemaining(int seconds) {
    final int days = seconds ~/ 86400;
    final int months = days ~/ 30;
    final int remDays = days % 30;
    if (months > 0) {
      return '$months mo $remDays d';
    }
    if (days > 0) {
      return '$days d';
    }
    final int hours = (seconds ~/ 3600).clamp(1, 23);
    return '$hours h';
  }
}
