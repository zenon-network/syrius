import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:nested/nested.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the paginated list of ZTS tokens available on the network.
class TokensCard extends StatelessWidget {
  /// Creates a new instance.
  const TokensCard({super.key});

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
          child: const _View(),
        ),
      ],
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.tokens,
        description: context.l10n.tokensCardDescription,
      ),
      onRefreshPressed: () {
        _searchController.clear();
        context.read<TokensBloc>().add(
          const InfiniteListRefreshRequested(),
        );
        context.read<SearchTokenBloc>().add(
          const SearchTokenRequested(query: '', refresh: true),
        );
      },
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.searchTokenHint,
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon: ClearContentButton(controller: _searchController),
              ),
              onChanged: _onSearchChanged,
            ),
            kVerticalSpacing,
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (_, TextEditingValue value, _) {
                  return value.text.isEmpty
                      ? _buildTokensList()
                      : _buildSearchToken(searchQuery: value.text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokensList() {
    return BlocBuilder<TokensBloc, InfiniteListState<Token>>(
      builder: (BuildContext context, InfiniteListState<Token> state) {
        return switch (state.status) {
          InfiniteListStatus.initial => const SyriusLoadingWidget(),
          InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
          InfiniteListStatus.success => _TokensGrid(
            hasReachedMax: state.hasReachedMax,
            onScrollReachedBottom: () {
              context.read<TokensBloc>().add(
                const InfiniteListMoreRequested(),
              );
            },
            onTokenUpdated: () {
              context.read<TokensBloc>().add(
                const InfiniteListRefreshRequested(),
              );
            },
            tokens: state.data!,
          ),
        };
      },
    );
  }

  Widget _buildSearchToken({
    required String searchQuery,
  }) {
    return BlocBuilder<SearchTokenBloc, SearchTokenState>(
      builder: (BuildContext context, SearchTokenState state) {
        if (state.query != searchQuery) {
          return const SyriusLoadingWidget();
        }

        return switch (state.status) {
          SearchTokenStatus.initial => const SyriusLoadingWidget(),
          SearchTokenStatus.loading => const SyriusLoadingWidget(),
          SearchTokenStatus.failure => SyriusErrorWidget(state.error!),
          SearchTokenStatus.success => _TokensGrid(
            hasReachedMax: state.hasReachedMax,
            onScrollReachedBottom: () {
              context.read<SearchTokenBloc>().add(
                const SearchTokenMoreRequested(),
              );
            },
            onTokenUpdated: () {
              context.read<SearchTokenBloc>().add(
                SearchTokenRequested(query: searchQuery, refresh: true),
              );
            },
            tokens: state.tokens,
          ),
        };
      },
    );
  }

  void _onSearchChanged(String value) {
    final String query = value.trim();
    context.read<SearchTokenBloc>().add(
      SearchTokenRequested(query: query),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _TokensGrid extends StatelessWidget {
  const _TokensGrid({
    required this._hasReachedMax,
    required this._onScrollReachedBottom,
    required this._onTokenUpdated,
    required this._tokens,
  });

  final bool _hasReachedMax;
  final VoidCallback _onScrollReachedBottom;
  final VoidCallback _onTokenUpdated;
  final List<Token> _tokens;

  @override
  Widget build(BuildContext context) {
    final List<Token> tokens = _sortTokens(_tokens);

    return InfiniteScrollGrid<Token>(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 1.25,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        crossAxisCount: 2,
      ),
      hasReachedMax: _hasReachedMax,
      itemBuilder: (_, Token token, _) => TokenCard(
        favoritesCallback: _onTokenUpdated,
        token: token,
      ),
      itemKeyGenerator: (Token token) => ValueKey<String>(
        token.tokenStandard.toString(),
      ),
      items: tokens,
      onScrollReachedBottom: _onScrollReachedBottom,
    );
  }

  List<Token> _sortTokens(List<Token> tokens) {
    final List<Token> ztsTokens = tokens
        .where(
          (Token token) => !<TokenStandard>{
            kZnnCoin.tokenStandard,
            kQsrCoin.tokenStandard,
          }.contains(token.tokenStandard),
        )
        .toList();

    final List<Token> ownedTokens =
        ztsTokens
            .where(
              (Token token) =>
                  kDefaultAddressList.contains(token.owner.toString()),
            )
            .toList()
          ..addAll(
            ztsTokens.where(
              (Token token) =>
                  !kDefaultAddressList.contains(token.owner.toString()),
            ),
          );

    final Box<dynamic> favoriteTokens = Hive.box(kFavoriteTokensBox);
    final List<Token> sortedTokens =
        ownedTokens
            .where(
              (Token token) => favoriteTokens.values.contains(
                token.tokenStandard.toString(),
              ),
            )
            .toList()
          ..addAll(
            ownedTokens.where(
              (Token token) => !favoriteTokens.values.contains(
                token.tokenStandard.toString(),
              ),
            ),
          );

    return sortedTokens;
  }
}
