import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_map/bloc/token_map_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the paginated list of ZTS tokens available on the network.
class TokenMapCard extends StatelessWidget {
  /// Creates a new instance.
  const TokenMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TokenMapBloc>(
      create: (_) =>
          TokenMapBloc(zenon: zenon!)..add(const InfiniteListRequested()),
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
        title: context.l10n.tokenMapTitle,
        description: context.l10n.tokenMapDescription,
      ),
      onRefreshPressed: () {
        _searchController.clear();
        context.read<TokenMapBloc>().add(
          const InfiniteListRefreshRequested(),
        );
      },
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            InputField(
              controller: _searchController,
              hintText: context.l10n.searchTokenBySymbol,
              suffixIcon: const Icon(
                Icons.search,
                color: Colors.green,
              ),
              onChanged: _onSearchChanged,
            ),
            kVerticalSpacing,
            Expanded(
              child: BlocBuilder<TokenMapBloc, InfiniteListState<Token>>(
                builder: (_, InfiniteListState<Token> state) {
                  return switch (state.status) {
                    InfiniteListStatus.initial => const SyriusLoadingWidget(),
                    InfiniteListStatus.failure => SyriusErrorWidget(
                      state.error!,
                    ),
                    InfiniteListStatus.success => _TokenMapGrid(
                      hasReachedMax: state.hasReachedMax,
                      onScrollReachedBottom: () {
                        context.read<TokenMapBloc>().add(
                          const InfiniteListMoreRequested(),
                        );
                      },
                      onTokenUpdated: () {
                        context.read<TokenMapBloc>().add(
                          const InfiniteListRefreshRequested(),
                        );
                      },
                      tokens: state.data!,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String _) {}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _TokenMapGrid extends StatelessWidget {
  const _TokenMapGrid({
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
        childAspectRatio: 100 / 80,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        crossAxisCount: 2,
      ),
      hasReachedMax: _hasReachedMax,
      itemBuilder: (_, Token token, _) => TokenCard(
        token,
        _onTokenUpdated,
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
