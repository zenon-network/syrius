import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// Redesigned two-column Plasma tab with left glow gauge + collapsible
/// address breakdown, and right Fuse drawer + multi-select cancel table
/// (Screens 21–22).
class PlasmaTabChild extends StatefulWidget {
  /// Creates a [PlasmaTabChild].
  const PlasmaTabChild({super.key});

  @override
  State<PlasmaTabChild> createState() => _PlasmaTabChildState();
}

class _PlasmaTabChildState extends State<PlasmaTabChild> {
  static final NumberFormat _intFormat = NumberFormat.decimalPattern();
  static final NumberFormat _amountFormat = NumberFormat('#,##0.####');

  bool _showFuseDrawer = false;
  bool _otherAddressesExpanded = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();
  final Set<Hash> _selectedFusionIds = <Hash>{};
  bool _fusing = false;
  bool _batchCancelling = false;

  @override
  void initState() {
    super.initState();
    _beneficiaryController.text = kSelectedAddress ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Address address = Address.parse(kSelectedAddress!);
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<FusedPlasmaBloc>(
          create: (_) =>
              FusedPlasmaBloc(zenon: zenon!)
                ..add(InfiniteListRequested(address: address)),
        ),
        BlocProvider<FusePlasmaBloc>(
          create: (_) => FusePlasmaBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<CancelPlasmaBloc>(
          create: (_) => CancelPlasmaBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
      ],
      child: Builder(builder: _buildView),
    );
  }

  Widget _buildView(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return MultiBlocListener(
      listeners: <SingleChildWidget>[
        BlocListener<FusePlasmaBloc, FusePlasmaState>(
          listener: (BuildContext context, FusePlasmaState state) {
            if (state is FusePlasmaDone) {
              setState(() {
                _fusing = false;
                _amountController.clear();
                _showFuseDrawer = false;
              });
              _refreshAll(context);
            } else if (state is FusePlasmaFailure) {
              setState(() => _fusing = false);
              unawaited(
                NotificationUtils.sendNotificationError(
                  state.exception,
                  context.l10n.plasmaFusingError,
                ),
              );
            }
          },
        ),
        BlocListener<CancelPlasmaBloc, CancelPlasmaState>(
          listener: (BuildContext context, CancelPlasmaState state) {
            if (state is CancelPlasmaDone || state is CancelPlasmaFailure) {
              if (_batchCancelling) {
                setState(() => _batchCancelling = false);
              }
              _refreshAll(context);
            }
          },
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(width: 310, child: _buildLeftGaugePanel(context, tokens)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTopSummaryBar(context, tokens, uiPrefs),
                if (_showFuseDrawer) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildFuseDrawer(context, tokens, uiPrefs),
                ],
                const SizedBox(height: 12),
                Expanded(child: _buildFusedTableCard(context, tokens, uiPrefs)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftGaugePanel(BuildContext context, SyriusThemeTokens tokens) {
    return Consumer<PlasmaGeneratedNotifier>(
      builder: (_, _, _) =>
          BlocBuilder<PlasmaStatsBloc, InfiniteListState<PlasmaInfoWrapper>>(
            builder:
                (
                  BuildContext context,
                  InfiniteListState<PlasmaInfoWrapper> state,
                ) {
                  final List<PlasmaInfoWrapper> entries =
                      state.data ?? const <PlasmaInfoWrapper>[];
                  PlasmaInfoWrapper? current;
                  for (final PlasmaInfoWrapper e in entries) {
                    if (e.address == kSelectedAddress) {
                      current = e;
                      break;
                    }
                  }
                  current ??= entries.isNotEmpty ? entries.first : null;
                  final int plasmaVal = current?.plasmaInfo.currentPlasma ?? 0;
                  final int maxPlasma = math.max(
                    current?.plasmaInfo.maxPlasma ?? 100000,
                    1,
                  );
                  final BigInt fusedQsr =
                      current?.plasmaInfo.qsrAmount ?? BigInt.zero;
                  final double progress = (plasmaVal / maxPlasma).clamp(
                    0.0,
                    1.0,
                  );
                  final int sendsEst = plasmaVal ~/ 21000;
                  final String level = _plasmaLevel(plasmaVal);

                  final List<PlasmaInfoWrapper> others = entries
                      .where(
                        (PlasmaInfoWrapper e) => e.address != kSelectedAddress,
                      )
                      .toList();
                  final int lowCount = others
                      .where(
                        (PlasmaInfoWrapper e) =>
                            e.plasmaInfo.currentPlasma < 42000,
                      )
                      .length;

                  return SyriusCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: <Color>[
                                      const Color(
                                        0xFF7B61FF,
                                      ).withValues(alpha: 0.45),
                                      tokens.qsrBlue.withValues(alpha: 0.12),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 46,
                                  color: context.isDarkMode
                                      ? Colors.white
                                      : tokens.qsrBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _intFormat.format(plasmaVal),
                                style: tokens.monoStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${context.l10n.plasma.toUpperCase()} · $level',
                                style: tokens.microLabelStyle(),
                              ),
                              const SizedBox(height: 18),
                              SyriusPlasmaBar(progress: progress),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    '${context.l10n.fused} '
                                    '${_formatRaw(
                                      fusedQsr,
                                      kQsrCoin.decimals,
                                    )} QSR',
                                    style: tokens.monoStyle(
                                      fontSize: 12,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'About $sendsEst sends',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SyriusDivider(),
                        InkWell(
                          onTap: () => setState(
                            () => _otherAddressesExpanded =
                                !_otherAddressesExpanded,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  context.l10n.otherAddresses,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${others.length}',
                                  style: tokens.monoStyle(
                                    fontSize: 12,
                                    color: tokens.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                if (!_otherAddressesExpanded && lowCount > 0)
                                  Text(
                                    '$lowCount low',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  _otherAddressesExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 17,
                                  color: tokens.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_otherAddressesExpanded &&
                            others.isNotEmpty) ...<Widget>[
                          const SyriusDivider(),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              itemCount: others.length,
                              itemBuilder: (_, int i) {
                                final PlasmaInfoWrapper w = others[i];
                                final double p =
                                    (w.plasmaInfo.currentPlasma /
                                            math.max(w.plasmaInfo.maxPlasma, 1))
                                        .clamp(0.0, 1.0);
                                final String lvl = _plasmaLevel(
                                  w.plasmaInfo.currentPlasma,
                                );
                                return InkWell(
                                  onTap: () => setState(() {
                                    _beneficiaryController.text = w.address;
                                    _showFuseDrawer = true;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            ZenonAddressUtils.getLabel(
                                              w.address,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: tokens.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: SyriusPlasmaBar(
                                            progress: p,
                                            height: 4,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 42,
                                          child: Text(
                                            lvl,
                                            textAlign: TextAlign.right,
                                            style: tokens.microLabelStyle(
                                              color: lvl == 'LOW'
                                                  ? tokens.warning
                                                  : tokens.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
          ),
    );
  }

  Widget _buildTopSummaryBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final MultipleBalanceState balState = context
        .watch<MultipleBalanceBloc>()
        .state;
    final BigInt availableQsr =
        balState.data?[kSelectedAddress]?.getBalance(kQsrCoin.tokenStandard) ??
        BigInt.zero;
    final InfiniteListState<FusionEntryWrapper> fusedState = context
        .watch<FusedPlasmaBloc>()
        .state;
    final List<FusionEntryWrapper> entries =
        fusedState.data ?? const <FusionEntryWrapper>[];
    BigInt totalFused = BigInt.zero;
    for (final FusionEntryWrapper e in entries) {
      totalFused += e.fusionEntry.qsrAmount;
    }

    return SyriusCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          SyriusMetricBlock(
            label: context.l10n.available,
            value: uiPrefs.hideBalances
                ? '••••'
                : _formatRaw(availableQsr, kQsrCoin.decimals),
            valueSuffix: kQsrCoin.symbol,
            suffixColor: tokens.qsrBlue,
          ),
          const SizedBox(width: 28),
          SyriusMetricBlock(
            label: context.l10n.fusedByYou,
            value: uiPrefs.hideBalances
                ? '••••'
                : _formatRaw(totalFused, kQsrCoin.decimals),
            valueSuffix: kQsrCoin.symbol,
            suffixColor: tokens.qsrBlue,
            secondaryText: 'in ${entries.length} entries',
          ),
          const Spacer(),
          if (_showFuseDrawer)
            SyriusPillButton(
              label: context.l10n.close,
              icon: Icons.close_rounded,
              height: 38,
              onPressed: () => setState(() => _showFuseDrawer = false),
            )
          else
            SyriusGradientButton(
              label: context.l10n.fuse,
              icon: Icons.bolt_rounded,
              height: 38,
              onPressed: () => setState(() => _showFuseDrawer = true),
            ),
        ],
      ),
    );
  }

  Widget _buildFuseDrawer(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final MultipleBalanceState balState = context
        .watch<MultipleBalanceBloc>()
        .state;
    final BigInt availableQsr =
        balState.data?[kSelectedAddress]?.getBalance(kQsrCoin.tokenStandard) ??
        BigInt.zero;
    final String amountText = _amountController.text.trim();
    final String beneficiary = _beneficiaryController.text.trim();

    final String? amountError = amountText.isNotEmpty
        ? InputValidators.correctValue(
            amountText,
            availableQsr,
            kQsrCoin.decimals,
            fuseMinQsrAmount,
            canBeEqualToMin: true,
            l10n: context.l10n,
          )
        : null;
    final String? addrError = beneficiary.isNotEmpty
        ? InputValidators.checkAddress(beneficiary, l10n: context.l10n)
        : null;
    final bool valid =
        amountText.isNotEmpty &&
        beneficiary.isNotEmpty &&
        amountError == null &&
        addrError == null;

    return SyriusCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.amount.toUpperCase(),
                      style: tokens.microLabelStyle(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
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
                                onTap: availableQsr > BigInt.zero
                                    ? () => setState(() {
                                        _amountController.text = availableQsr
                                            .addDecimals(kQsrCoin.decimals);
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
                                'QSR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.qsrBlue,
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
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('FOR', style: tokens.microLabelStyle()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _beneficiaryController,
                      onChanged: (_) => setState(() {}),
                      style: tokens.monoStyle(
                        color: tokens.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: tokens.surfaceSubtle,
                        hintText: context.l10n.beneficiaryAddress,
                        errorText: addrError,
                        suffixIcon: PopupMenuButton<String>(
                          color: tokens.surface,
                          tooltip: context.l10n.anotherAddress,
                          onSelected: (String addr) => setState(
                            () => _beneficiaryController.text = addr,
                          ),
                          itemBuilder: (_) => kDefaultAddressList
                              .whereType<String>()
                              .map(
                                (String a) => PopupMenuItem<String>(
                                  value: a,
                                  child: Text(
                                    '${ZenonAddressUtils.getLabel(a)} '
                                    '(${_shorten(a)})',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  context.l10n.anotherAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.textMuted,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 15,
                                  color: tokens.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SyriusGradientButton(
                height: 42,
                isLoading: _fusing,
                label: amountText.isNotEmpty
                    ? '${context.l10n.fuse} $amountText QSR'
                    : context.l10n.fuse,
                onPressed: valid
                    ? () {
                        setState(() => _fusing = true);
                        context.read<FusePlasmaBloc>().add(
                          FusePlasmaRequested(
                            beneficiaryAddress: beneficiary,
                            amount: amountText.extractDecimals(
                              kQsrCoin.decimals,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Fused QSR can be taken back after 10 hours.',
            style: TextStyle(fontSize: 12, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFusedTableCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return BlocBuilder<FusedPlasmaBloc, InfiniteListState<FusionEntryWrapper>>(
      builder:
          (BuildContext context, InfiniteListState<FusionEntryWrapper> state) {
        final List<FusionEntryWrapper> entries =
            state.data ?? const <FusionEntryWrapper>[];
        return SyriusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                child: Row(
                  children: <Widget>[
                    Text(
                      context.l10n.fused,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entries.length}',
                      style: tokens.monoStyle(
                        fontSize: 12,
                        color: tokens.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedFusionIds.isNotEmpty) ...<Widget>[
                      Text(
                        '${_selectedFusionIds.length} ${context.l10n.selected}',
                        style: TextStyle(
                          fontSize: 12,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SyriusPillButton(
                        label: 'Cancel ${_selectedFusionIds.length} fuses',
                        compact: true,
                        isLoading: _batchCancelling,
                        onPressed: () => _cancelSelectedFusions(context),
                      ),
                    ] else
                      Text(
                        context.l10n.selectRowsToCancelTogether,
                        style: TextStyle(fontSize: 12, color: tokens.textMuted),
                      ),
                  ],
                ),
              ),
              const SyriusDivider(),
              Expanded(
                child: switch (state.status) {
                  InfiniteListStatus.initial => const SyriusLoadingWidget(),
                  InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
                  InfiniteListStatus.success =>
                    entries.isEmpty
                        ? SyriusEmptyState(message: context.l10n.noneYet)
                        : _buildEntriesTable(context, tokens, uiPrefs, entries),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntriesTable(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
    List<FusionEntryWrapper> entries,
  ) {
    final int lastHeight =
        context.read<FusedPlasmaBloc>().lastMomentumHeight ?? 0;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 34),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.amount.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text('BENEFICIARY', style: tokens.microLabelStyle()),
              ),
              Expanded(
                flex: 3,
                child: Text('EXPIRES', style: tokens.microLabelStyle()),
              ),
              const SizedBox(width: 90),
            ],
          ),
        ),
        const SyriusDivider(),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SyriusDivider(),
            itemBuilder: (BuildContext context, int index) {
              final FusionEntryWrapper wrapper = entries[index];
              final FusionEntry entry = wrapper.fusionEntry;
              final bool revocable = wrapper.isRevocable;
              final bool selected = _selectedFusionIds.contains(entry.id);
              final String beneStr = entry.beneficiary.toString();
              final bool isSelf = beneStr == kSelectedAddress;
              final String beneLabel =
                  uiPrefs.contactLabelFor(beneStr) ??
                  ZenonAddressUtils.getLabel(beneStr);
              final int remainingBlocks = math.max(
                entry.expirationHeight - lastHeight,
                0,
              );
              final Duration remainingDur =
                  kIntervalBetweenMomentums * remainingBlocks;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 34,
                      child: Checkbox(
                        value: selected,
                        onChanged: revocable
                            ? (bool? val) {
                                setState(() {
                                  if (val ?? false) {
                                    _selectedFusionIds.add(entry.id);
                                  } else {
                                    _selectedFusionIds.remove(entry.id);
                                  }
                                });
                              }
                            : null,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        uiPrefs.hideBalances
                            ? '•••• QSR'
                            : '${_formatRaw(
                                  entry.qsrAmount,
                                  kQsrCoin.decimals,
                                )} QSR',
                        style: tokens.monoStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              beneLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelf) ...<Widget>[
                            const SizedBox(width: 7),
                            const SyriusStatusBadge(label: 'this'),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: revocable
                            ? SyriusStatusBadge(
                                label: context.l10n.cancelable,
                                tone: SyriusBadgeTone.success,
                                icon: Icons.check_rounded,
                              )
                            : SyriusStatusBadge(
                                label: _formatDuration(remainingDur),
                                tone: SyriusBadgeTone.info,
                                icon: Icons.lock_outline_rounded,
                              ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: revocable
                            ? CancelPlasmaButton(
                                plasmaHash: entry.id,
                                onCancelled: () => _refreshAll(context),
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

  void _cancelSelectedFusions(BuildContext context) {
    final List<Hash> hashes = _selectedFusionIds.toList();
    setState(() {
      _batchCancelling = true;
      _selectedFusionIds.clear();
    });
    final CancelPlasmaBloc cancelBloc = context.read<CancelPlasmaBloc>();
    for (final Hash id in hashes) {
      cancelBloc.add(CancelPlasmaRequested(plasmaHash: id));
    }
  }

  void _refreshAll(BuildContext context) {
    final Address addr = Address.parse(kSelectedAddress!);
    context.read<FusedPlasmaBloc>().add(
      InfiniteListRefreshRequested(address: addr),
    );
    context.read<PlasmaStatsBloc>().add(const InfiniteListRefreshRequested());
    sl<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );
  }

  static String _plasmaLevel(int plasma) {
    if (plasma >= 84000) {
      return 'HIGH';
    }
    if (plasma >= 42000) {
      return 'MED';
    }
    if (plasma > 0) {
      return 'LOW';
    }
    return 'NONE';
  }

  static String _formatRaw(BigInt raw, int decimals) {
    final String s = raw.addDecimals(decimals);
    final double? n = double.tryParse(s);
    return n != null ? _amountFormat.format(n) : s;
  }

  static String _formatDuration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '$h h $m m';
    }
    return '${math.max(m, 1)} m';
  }

  static String _shorten(String address) {
    if (address.length <= 14) {
      return address;
    }
    return '${address.substring(0, 6)}...'
        '${address.substring(address.length - 4)}';
  }
}
