import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _TokenFilter { held, favorites, all }

enum _OwnerActionTab { mint, burn, transfer, flags }

/// Redesigned Tokens screen matching mockups Screens 23–24.
class TokensTabChild extends StatelessWidget {
  /// Creates a [TokensTabChild].
  const TokensTabChild({
    required this._onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<TokensBloc>(
          create: (_) =>
              TokensBloc(zenon: zenon!)..add(const InfiniteListRequested()),
        ),
        BlocProvider<SearchTokenBloc>(
          create: (_) => SearchTokenBloc(zenon: zenon!),
        ),
      ],
      child: _TokensWorkspaceView(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
      ),
    );
  }
}

class _TokensWorkspaceView extends StatefulWidget {
  const _TokensWorkspaceView({
    required this.onStepperNotificationSeeMorePressed,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<_TokensWorkspaceView> createState() => _TokensWorkspaceViewState();
}

class _TokensWorkspaceViewState extends State<_TokensWorkspaceView> {
  final TextEditingController _searchController = TextEditingController();
  _TokenFilter _filter = _TokenFilter.held;
  String? _expandedZts;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<MultipleBalanceBloc>()) {
      sl<MultipleBalanceBloc>().add(
        MultipleBalanceFetch(
          addresses: kDefaultAddressList.whereType<String>().toList(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> _favoriteStandards() {
    if (!Hive.isBoxOpen(kFavoriteTokensBox)) {
      return const <String>{};
    }
    return Hive.box<dynamic>(
      kFavoriteTokensBox,
    ).values.map((dynamic v) => v.toString()).toSet();
  }

  void _refreshTokens() {
    _searchController.clear();
    context.read<TokensBloc>().add(const InfiniteListRefreshRequested());
    context.read<SearchTokenBloc>().add(
      const SearchTokenRequested(query: '', refresh: true),
    );
    if (sl.isRegistered<MultipleBalanceBloc>()) {
      sl<MultipleBalanceBloc>().add(
        MultipleBalanceFetch(
          addresses: kDefaultAddressList.whereType<String>().toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return Consumer<SelectedAddressNotifier>(
      builder: (_, _, _) {
        return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
          builder: (_, MultipleBalanceState balanceState) {
            final AccountInfo? selectedAccount =
                balanceState.data?[kSelectedAddress];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTopSummaryBar(context, tokens, selectedAccount),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildTokensTableCard(
                    context,
                    tokens,
                    selectedAccount,
                    uiPrefs,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopSummaryBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    AccountInfo? accountInfo,
  ) {
    final List<BalanceInfoListItem> heldZts =
        (accountInfo?.balanceInfoList ?? <BalanceInfoListItem>[])
            .where(
              (BalanceInfoListItem item) =>
                  item.token != null &&
                  item.balance != null &&
                  item.balance! > BigInt.zero &&
                  item.token!.tokenStandard != kZnnCoin.tokenStandard &&
                  item.token!.tokenStandard != kQsrCoin.tokenStandard,
            )
            .toList();

    return BlocBuilder<TokensBloc, InfiniteListState<Token>>(
      builder: (_, InfiniteListState<Token> tokenState) {
        final List<Token> networkTokens = tokenState.data ?? const <Token>[];
        final int issuedByYou = networkTokens
            .where(
              (Token t) =>
                  kDefaultAddressList.contains(t.owner.toString()) &&
                  t.tokenStandard != kZnnCoin.tokenStandard &&
                  t.tokenStandard != kQsrCoin.tokenStandard,
            )
            .length;

        return SyriusCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 42,
                child: Lottie.asset(
                  'assets/lottie/ic_anim_zts.json',
                  repeat: false,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.toll_outlined,
                    size: 28,
                    color: tokens.znnGreen,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              SyriusMetricBlock(
                label: context.l10n.youHold,
                value: '${heldZts.length}',
                valueSuffix: context.l10n.tokens.toLowerCase(),
              ),
              const SizedBox(width: 28),
              SyriusMetricBlock(
                label: context.l10n.issuedByYou,
                value: '$issuedByYou',
              ),
              const SizedBox(width: 28),
              SyriusMetricBlock(
                label: context.l10n.issueFee,
                value: '1',
                valueSuffix: kZnnCoin.symbol,
                suffixColor: tokens.znnGreen,
              ),
              const Spacer(),
              SyriusGradientButton(
                label: context.l10n.createToken,
                icon: Icons.add,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                onPressed: () {
                  final AllTokensBloc allTokensBloc = context
                      .read<AllTokensBloc>();
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext routeContext) =>
                          BlocProvider<AllTokensBloc>.value(
                            value: allTokensBloc,
                            child: StepperScreen(
                              breadcrumbParent: routeContext.l10n.tokens,
                              title: routeContext.l10n.createToken,
                              stepper: const CreateTokenStepperPage(),
                              onStepperNotificationSeeMorePressed:
                                  widget.onStepperNotificationSeeMorePressed,
                            ),
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
  }

  Widget _buildTokensTableCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AccountInfo? accountInfo,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return SyriusCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: <Widget>[
                SyriusSegmentedControl<_TokenFilter>(
                  selected: _filter,
                  onChanged: (_TokenFilter next) {
                    setState(() {
                      _filter = next;
                      _expandedZts = null;
                    });
                  },
                  options: <SyriusSegmentOption<_TokenFilter>>[
                    SyriusSegmentOption<_TokenFilter>(
                      value: _TokenFilter.held,
                      label: context.l10n.held,
                    ),
                    SyriusSegmentOption<_TokenFilter>(
                      value: _TokenFilter.favorites,
                      label: context.l10n.favorites,
                    ),
                    SyriusSegmentOption<_TokenFilter>(
                      value: _TokenFilter.all,
                      label: context.l10n.all,
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 250,
                  child: SyriusSearchField(
                    controller: _searchController,
                    hintText: context.l10n.searchTokenHint,
                    onChanged: (String value) {
                      setState(() {});
                      context.read<SearchTokenBloc>().add(
                        SearchTokenRequested(query: value.trim()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: context.l10n.refresh,
                  splashRadius: 16,
                  iconSize: 16,
                  color: tokens.textMuted,
                  onPressed: _refreshTokens,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 34),
                Expanded(
                  flex: 4,
                  child: Text(
                    context.l10n.token.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.youHold.toUpperCase(),
                    textAlign: TextAlign.right,
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Text(
                    context.l10n.supply.toUpperCase(),
                    textAlign: TextAlign.right,
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Text(
                    context.l10n.owner.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (_, TextEditingValue searchValue, _) {
                if (searchValue.text.trim().isNotEmpty) {
                  return _buildSearchResults(
                    context,
                    tokens,
                    accountInfo,
                    uiPrefs,
                    searchValue.text.trim(),
                  );
                }
                return _buildAllTokensList(
                  context,
                  tokens,
                  accountInfo,
                  uiPrefs,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    SyriusThemeTokens themeTokens,
    AccountInfo? accountInfo,
    AppUiPreferencesNotifier uiPrefs,
    String query,
  ) {
    return BlocBuilder<SearchTokenBloc, SearchTokenState>(
      builder: (BuildContext context, SearchTokenState state) {
        if (state.query != query) {
          return const SyriusLoadingWidget();
        }
        return switch (state) {
          SearchTokenInitial() ||
          SearchTokenLoading() => const SyriusLoadingWidget(),
          SearchTokenFailure(:final SyriusException exception) =>
            SyriusErrorWidget(exception),
          SearchTokenPopulated(:final List<Token> tokens) => _buildTokenRows(
            context,
            themeTokens,
            accountInfo,
            uiPrefs,
            _excludeNative(tokens),
            hasReachedMax: true,
          ),
        };
      },
    );
  }

  Widget _buildAllTokensList(
    BuildContext context,
    SyriusThemeTokens tokens,
    AccountInfo? accountInfo,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return BlocBuilder<TokensBloc, InfiniteListState<Token>>(
      builder: (BuildContext context, InfiniteListState<Token> state) {
        return switch (state.status) {
          InfiniteListStatus.initial => const SyriusLoadingWidget(),
          InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
          InfiniteListStatus.success => _buildTokenRows(
            context,
            tokens,
            accountInfo,
            uiPrefs,
            _filterTokens(state.data ?? const <Token>[], accountInfo),
            hasReachedMax: state.hasReachedMax || _filter == _TokenFilter.held,
            dataIdentity: state.data,
          ),
        };
      },
    );
  }

  List<Token> _excludeNative(List<Token> input) {
    return input
        .where(
          (Token token) =>
              token.tokenStandard != kZnnCoin.tokenStandard &&
              token.tokenStandard != kQsrCoin.tokenStandard,
        )
        .toList();
  }

  List<Token> _filterTokens(List<Token> all, AccountInfo? accountInfo) {
    final List<Token> nonNative = _excludeNative(all);
    final Map<String, Token> merged = <String, Token>{
      for (final Token t in nonNative) t.tokenStandard.toString(): t,
    };

    if (accountInfo?.balanceInfoList != null) {
      for (final BalanceInfoListItem item in accountInfo!.balanceInfoList!) {
        final Token? token = item.token;
        if (token != null &&
            token.tokenStandard != kZnnCoin.tokenStandard &&
            token.tokenStandard != kQsrCoin.tokenStandard) {
          merged.putIfAbsent(token.tokenStandard.toString(), () => token);
        }
      }
    }

    final Set<String> favs = _favoriteStandards();
    final List<Token> items = merged.values.toList();
    return switch (_filter) {
      _TokenFilter.held =>
        items
            .where(
              (Token t) =>
                  (accountInfo?.getBalance(t.tokenStandard) ?? BigInt.zero) >
                      BigInt.zero ||
                  kDefaultAddressList.contains(t.owner.toString()),
            )
            .toList(),
      _TokenFilter.favorites =>
        items
            .where((Token t) => favs.contains(t.tokenStandard.toString()))
            .toList(),
      _TokenFilter.all => nonNative,
    };
  }

  Widget _buildTokenRows(
    BuildContext context,
    SyriusThemeTokens tokens,
    AccountInfo? accountInfo,
    AppUiPreferencesNotifier uiPrefs,
    List<Token> items, {
    required bool hasReachedMax,
    Object? dataIdentity,
  }) {
    if (items.isEmpty && hasReachedMax) {
      return SyriusEmptyState(message: context.l10n.noTokensYet);
    }

    return SyriusPaginatedListView(
      itemCount: items.length,
      hasReachedMax: hasReachedMax,
      isLoadingMore: context.read<TokensBloc>().isLoadingMoreListenable,
      dataIdentity: dataIdentity ?? items,
      onLoadMore: () =>
          context.read<TokensBloc>().add(const InfiniteListMoreRequested()),
      itemBuilder: (BuildContext context, int index) {
        final Token token = items[index];
        final String zts = token.tokenStandard.toString();
        final bool expanded = _expandedZts == zts;
        return _TokenExpandableRow(
          key: ValueKey<String>(zts),
          token: token,
          accountInfo: accountInfo,
          hideBalances: uiPrefs.hideBalances,
          explorerBaseUrl: uiPrefs.selectedExplorer,
          expanded: expanded,
          onToggleExpand: () {
            setState(() {
              _expandedZts = expanded ? null : zts;
            });
          },
          onFavoriteChanged: () => setState(() {}),
          onMutationSuccess: _refreshTokens,
        );
      },
    );
  }
}

class _TokenExpandableRow extends StatefulWidget {
  const _TokenExpandableRow({
    required this.token,
    required this.accountInfo,
    required this.hideBalances,
    required this.explorerBaseUrl,
    required this.expanded,
    required this.onToggleExpand,
    required this.onFavoriteChanged,
    required this.onMutationSuccess,
    super.key,
  });

  final Token token;
  final AccountInfo? accountInfo;
  final bool hideBalances;
  final String explorerBaseUrl;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onFavoriteChanged;
  final VoidCallback onMutationSuccess;

  @override
  State<_TokenExpandableRow> createState() => _TokenExpandableRowState();
}

class _TokenExpandableRowState extends State<_TokenExpandableRow> {
  static final NumberFormat _compactFormat = NumberFormat.compact();
  _OwnerActionTab _ownerTab = _OwnerActionTab.mint;
  bool _showHolderBurn = false;

  bool get _isOwnerOnSelectedAddress =>
      kSelectedAddress == widget.token.owner.toString();

  bool get _isOwnedByWallet =>
      kDefaultAddressList.contains(widget.token.owner.toString());

  String _formatBalance(BigInt amount, int decimals) {
    if (widget.hideBalances) {
      return '••••';
    }
    return amount.addDecimals(decimals);
  }

  String _compactBigInt(BigInt value, int decimals) {
    final double asDouble =
        double.tryParse(value.addDecimals(decimals).replaceAll(',', '')) ?? 0;
    return _compactFormat.format(asDouble);
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final BigInt held =
        widget.accountInfo?.getBalance(widget.token.tokenStandard) ??
        BigInt.zero;
    final String ztsStr = widget.token.tokenStandard.toString();
    final String shortZts = ztsStr.length > 16
        ? '${ztsStr.substring(0, 8)}…${ztsStr.substring(ztsStr.length - 5)}'
        : ztsStr;
    final String ownerStr = widget.token.owner.toString();
    final String ownerLabel = _isOwnedByWallet
        ? (kAddressLabelMap[ownerStr] ?? widget.token.owner.toShortString())
        : widget.token.owner.toShortString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      color: widget.expanded
          ? tokens.surfaceElevated.withValues(alpha: 0.45)
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: widget.onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 34,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TokenFavorite(
                            token: widget.token,
                            callback: widget.onFavoriteChanged,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: <Widget>[
                        SyriusTokenAvatar(
                          symbol: widget.token.symbol,
                          color: ColorUtils.getTokenColor(
                            widget.token.tokenStandard,
                          ),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.token.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.token.symbol} · $shortZts',
                                overflow: TextOverflow.ellipsis,
                                style: tokens.monoStyle(
                                  fontSize: 11,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatBalance(held, widget.token.decimals),
                      textAlign: TextAlign.right,
                      style: tokens.monoStyle(
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          text: widget.token.totalSupply.addDecimals(
                            widget.token.decimals,
                          ),
                          style: tokens.monoStyle(
                            color: tokens.textPrimary,
                          ),
                          children: <InlineSpan>[
                            if (widget.token.isMintable &&
                                widget.token.maxSupply >
                                    widget.token.totalSupply)
                              TextSpan(
                                text:
                                    ' of ${_compactBigInt(
                                      widget.token.maxSupply,
                                      widget.token.decimals,
                                    )}',
                                style: tokens.monoStyle(
                                  fontSize: 11.5,
                                  color: tokens.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            ownerLabel,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.monoStyle(
                              fontSize: 12.5,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        if (_isOwnedByWallet) ...<Widget>[
                          const SizedBox(width: 8),
                          SyriusStatusBadge(label: context.l10n.you),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Icon(
                      widget.expanded
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
          if (widget.expanded) _buildExpandedDetails(context, tokens, held),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(
    BuildContext context,
    SyriusThemeTokens tokens,
    BigInt held,
  ) {
    final String explorerUrl =
        '${widget.explorerBaseUrl}token/${widget.token.tokenStandard}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 4, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Wrap(
                  spacing: 32,
                  runSpacing: 8,
                  children: <Widget>[
                    _buildMetaItem(
                      tokens,
                      context.l10n.decimalsLabel,
                      Text(
                        '${widget.token.decimals}',
                        style: tokens.monoStyle(
                          fontSize: 12.5,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    _buildMetaItem(
                      tokens,
                      context.l10n.domain,
                      widget.token.domain.isEmpty
                          ? Text(
                              '—',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: tokens.textMuted,
                              ),
                            )
                          : InkWell(
                              onTap: () => unawaited(
                                NavigationUtils.openUrl(widget.token.domain),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    widget.token.domain,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.open_in_new,
                                    size: 12,
                                    color: tokens.textMuted,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    _buildMetaItem(
                      tokens,
                      context.l10n.mintable,
                      Text(
                        widget.token.isMintable
                            ? context.l10n.yesByOwner
                            : context.l10n.no.capitalize(),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    _buildMetaItem(
                      tokens,
                      context.l10n.burnable,
                      Text(
                        widget.token.isBurnable
                            ? context.l10n.byAnyHolder
                            : context.l10n.no.capitalize(),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    if (_isOwnerOnSelectedAddress)
                      _buildMetaItem(
                        tokens,
                        context.l10n.utility,
                        Text(
                          widget.token.isUtility
                              ? context.l10n.yes.capitalize()
                              : context.l10n.no.capitalize(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (_isOwnerOnSelectedAddress)
                SyriusSegmentedControl<_OwnerActionTab>(
                  selected: _ownerTab,
                  onChanged: (_OwnerActionTab tab) {
                    setState(() => _ownerTab = tab);
                  },
                  options: <SyriusSegmentOption<_OwnerActionTab>>[
                    SyriusSegmentOption<_OwnerActionTab>(
                      value: _OwnerActionTab.mint,
                      label: context.l10n.mint,
                    ),
                    SyriusSegmentOption<_OwnerActionTab>(
                      value: _OwnerActionTab.burn,
                      label: context.l10n.burn,
                    ),
                    SyriusSegmentOption<_OwnerActionTab>(
                      value: _OwnerActionTab.transfer,
                      label: context.l10n.transferOwnership,
                    ),
                    SyriusSegmentOption<_OwnerActionTab>(
                      value: _OwnerActionTab.flags,
                      label: context.l10n.flags,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.token.isBurnable &&
                        held > BigInt.zero) ...<Widget>[
                      SyriusPillButton(
                        label: context.l10n.burn,
                        compact: true,
                        onPressed: () {
                          setState(() => _showHolderBurn = !_showHolderBurn);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    SyriusPillButton(
                      label: context.l10n.send,
                      compact: true,
                      onPressed: () {
                        final ShellNavigationController? nav =
                            Provider.of<ShellNavigationController?>(
                              context,
                              listen: false,
                            );
                        nav?.requestTransfer(mode: TransferMode.send);
                      },
                    ),
                    const SizedBox(width: 10),
                    SyriusGhostButton(
                      label: context.l10n.explorer.toLowerCase(),
                      icon: Icons.open_in_new,
                      onPressed: () =>
                          unawaited(NavigationUtils.openUrl(explorerUrl)),
                    ),
                  ],
                ),
            ],
          ),
          if (_isOwnerOnSelectedAddress) ...<Widget>[
            const SizedBox(height: 14),
            _buildOwnerActionPanel(context, tokens),
          ] else if (_showHolderBurn && widget.accountInfo != null) ...<Widget>[
            const SizedBox(height: 14),
            _InlineBurnForm(
              token: widget.token,
              accountInfo: widget.accountInfo!,
              onSuccess: widget.onMutationSuccess,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(SyriusThemeTokens tokens, String label, Widget value) {
    return SizedBox(
      width: 210,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 78,
            child: Text(label.toUpperCase(), style: tokens.microLabelStyle()),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildOwnerActionPanel(
    BuildContext context,
    SyriusThemeTokens tokens,
  ) {
    return switch (_ownerTab) {
      _OwnerActionTab.mint => _InlineMintForm(
        token: widget.token,
        onSuccess: widget.onMutationSuccess,
      ),
      _OwnerActionTab.burn =>
        widget.accountInfo == null
            ? const SizedBox.shrink()
            : _InlineBurnForm(
                token: widget.token,
                accountInfo: widget.accountInfo!,
                onSuccess: widget.onMutationSuccess,
              ),
      _OwnerActionTab.transfer => _InlineTransferForm(
        token: widget.token,
        onSuccess: widget.onMutationSuccess,
      ),
      _OwnerActionTab.flags => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: <Widget>[
            SyriusStatusBadge(
              label:
                  '${context.l10n.mintable}: '
                  '${widget.token.isMintable
                      ? context.l10n.yes
                      : context.l10n.no}',
              tone: widget.token.isMintable
                  ? SyriusBadgeTone.success
                  : SyriusBadgeTone.neutral,
            ),
            SyriusStatusBadge(
              label:
                  '${context.l10n.burnable}: '
                  '${widget.token.isBurnable
                      ? context.l10n.yes
                      : context.l10n.no}',
              tone: widget.token.isBurnable
                  ? SyriusBadgeTone.info
                  : SyriusBadgeTone.neutral,
            ),
            SyriusStatusBadge(
              label:
                  '${context.l10n.utility}: '
                  '${widget.token.isUtility
                      ? context.l10n.yes
                      : context.l10n.no}',
              tone: widget.token.isUtility
                  ? SyriusBadgeTone.warning
                  : SyriusBadgeTone.neutral,
            ),
          ],
        ),
      ),
    };
  }
}

class _InlineMintForm extends StatefulWidget {
  const _InlineMintForm({required this.token, required this.onSuccess});

  final Token token;
  final VoidCallback onSuccess;

  @override
  State<_InlineMintForm> createState() => _InlineMintFormState();
}

class _InlineMintFormState extends State<_InlineMintForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(
    text: kSelectedAddress ?? '',
  );

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final BigInt remaining = widget.token.maxSupply - widget.token.totalSupply;

    return BlocProvider<MintTokenBloc>(
      create: (_) => MintTokenBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: BlocConsumer<MintTokenBloc, MintTokenState>(
        listener: (BuildContext context, MintTokenState state) {
          if (state is MintTokenDone) {
            _amountController.clear();
            widget.onSuccess();
            unawaited(
              sl.get<NotificationsBloc>().addNotification(
                WalletNotification(
                  title: context.l10n.successfullyMinted(
                    state.accountBlock.amount.addDecimals(
                      widget.token.decimals,
                    ),
                    widget.token.symbol,
                  ),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  details: context.l10n.hashValue(
                    state.accountBlock.hash.toString(),
                  ),
                  type: NotificationType.paymentSent,
                ),
              ),
            );
          } else if (state is MintTokenFailure) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.exception,
                context.l10n.errorMintingToken(widget.token.symbol),
              ),
            );
          }
        },
        builder: (BuildContext context, MintTokenState state) {
          final String? amountErr = InputValidators.correctValue(
            _amountController.text,
            remaining,
            widget.token.decimals,
            BigInt.zero,
            l10n: context.l10n,
          );
          final String? addrErr = InputValidators.checkAddress(
            _addressController.text,
            l10n: context.l10n,
          );
          final bool canSubmit =
              widget.token.isMintable &&
              remaining > BigInt.zero &&
              _amountController.text.isNotEmpty &&
              amountErr == null &&
              addrErr == null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _amountController,
                        onChanged: (_) => setState(() {}),
                        inputFormatters:
                            FormatUtils.getAmountTextInputFormatters(
                              _amountController.text,
                            ),
                        style: tokens.monoStyle(),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '0',
                          suffixText: widget.token.symbol,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        onChanged: (_) => setState(() {}),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp('[0-9a-z]')),
                        ],
                        style: tokens.monoStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: context.l10n.beneficiaryAddress,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _addressController.text =
                                      kSelectedAddress ?? '';
                                });
                              },
                              child: Text(
                                context.l10n.thisAddress,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SyriusGradientButton(
                      label: context.l10n.mint,
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      isLoading: state is MintTokenLoading,
                      onPressed: canSubmit
                          ? () {
                              context.read<MintTokenBloc>().add(
                                MintTokenRequested(
                                  amount: _amountController.text
                                      .extractDecimals(widget.token.decimals),
                                  beneficiaryAddress: Address.parse(
                                    _addressController.text,
                                  ),
                                  token: widget.token,
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.leftUnderMaxSupply(
                  remaining.addDecimals(widget.token.decimals),
                ),
                style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InlineBurnForm extends StatefulWidget {
  const _InlineBurnForm({
    required this.token,
    required this.accountInfo,
    required this.onSuccess,
  });

  final Token token;
  final AccountInfo accountInfo;
  final VoidCallback onSuccess;

  @override
  State<_InlineBurnForm> createState() => _InlineBurnFormState();
}

class _InlineBurnFormState extends State<_InlineBurnForm> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final BigInt maxBurn = widget.accountInfo.getBalance(
      widget.token.tokenStandard,
    );

    return BlocProvider<BurnTokenBloc>(
      create: (_) => BurnTokenBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: BlocConsumer<BurnTokenBloc, BurnTokenState>(
        listener: (BuildContext context, BurnTokenState state) {
          if (state is BurnTokenDone) {
            _amountController.clear();
            widget.onSuccess();
          } else if (state is BurnTokenFailure) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.exception,
                context.l10n.errorBurningZts,
              ),
            );
          }
        },
        builder: (BuildContext context, BurnTokenState state) {
          final String? err = InputValidators.correctValue(
            _amountController.text,
            maxBurn,
            widget.token.decimals,
            BigInt.zero,
            l10n: context.l10n,
          );
          final bool canSubmit =
              _amountController.text.isNotEmpty && err == null;

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _amountController,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: FormatUtils.getAmountTextInputFormatters(
                      _amountController.text,
                    ),
                    style: tokens.monoStyle(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: context.l10n.amount,
                      errorText: _amountController.text.isEmpty ? null : err,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      suffixIcon: TextButton(
                        onPressed: () {
                          setState(() {
                            _amountController.text = maxBurn.addDecimals(
                              widget.token.decimals,
                            );
                          });
                        },
                        child: Text(
                          context.l10n.max.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.znnGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SyriusPillButton(
                  label: context.l10n.burn,
                  destructive: true,
                  isLoading: state is BurnTokenLoading,
                  onPressed: canSubmit
                      ? () {
                          context.read<BurnTokenBloc>().add(
                            BurnTokenRequested(
                              amount: _amountController.text.extractDecimals(
                                widget.token.decimals,
                              ),
                              token: widget.token,
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InlineTransferForm extends StatefulWidget {
  const _InlineTransferForm({required this.token, required this.onSuccess});

  final Token token;
  final VoidCallback onSuccess;

  @override
  State<_InlineTransferForm> createState() => _InlineTransferFormState();
}

class _InlineTransferFormState extends State<_InlineTransferForm> {
  final TextEditingController _ownerController = TextEditingController();

  @override
  void dispose() {
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return BlocProvider<TransferTokenBloc>(
      create: (_) => TransferTokenBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
      ),
      child: BlocConsumer<TransferTokenBloc, TransferTokenState>(
        listener: (BuildContext context, TransferTokenState state) {
          if (state is TransferTokenDone) {
            _ownerController.clear();
            widget.onSuccess();
          } else if (state is TransferTokenFailure) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.exception,
                context.l10n.errorTransferringTokenOwnership,
              ),
            );
          }
        },
        builder: (BuildContext context, TransferTokenState state) {
          final String? err = InputValidators.checkAddress(
            _ownerController.text,
            l10n: context.l10n,
          );
          final bool canSubmit =
              _ownerController.text.isNotEmpty && err == null;

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _ownerController,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-z]')),
                    ],
                    style: tokens.monoStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: context.l10n.newOwnerAddress,
                      errorText: _ownerController.text.isEmpty ? null : err,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SyriusGradientButton(
                  label: context.l10n.transfer,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  isLoading: state is TransferTokenLoading,
                  onPressed: canSubmit
                      ? () {
                          context.read<TransferTokenBloc>().add(
                            TransferTokenRequested(
                              newOwnerAddress: Address.parse(
                                _ownerController.text,
                              ),
                              token: widget.token,
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
