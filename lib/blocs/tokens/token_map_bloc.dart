import 'dart:async';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenMapBloc with RefreshBlocMixin {

  TokenMapBloc() {
    _onPageRequest.stream
        .flatMap(_fetchList)
        .listen(_onNewListingStateController.add)
        .addTo(_subscriptions);

    _onSearchInputChangedSubject.stream
        .flatMap((_) => _doRefreshResults())
        .listen(_onNewListingStateController.add)
        .addTo(_subscriptions);

    listenToWsRestart(refreshResults);
  }
  List<Token>? _allTokens;

  void refreshResults() {
    if (!_onSearchInputChangedSubject.isClosed) {
      onRefreshResultsRequest.add(null);
    }
  }

  Stream<InfiniteScrollBlocListingState<Token>> _doRefreshResults() async* {
    yield InfiniteScrollBlocListingState<Token>();
    yield* _fetchList(0);
  }

  static const _pageSize = 10;

  final _subscriptions = CompositeSubscription();

  final _onNewListingStateController =
      BehaviorSubject<InfiniteScrollBlocListingState<Token>>.seeded(
    InfiniteScrollBlocListingState<Token>(),
  );

  Stream<InfiniteScrollBlocListingState<Token>> get onNewListingState =>
      _onNewListingStateController.stream;

  final _onPageRequest = StreamController<int>();

  Sink<int> get onPageRequestSink => _onPageRequest.sink;

  final _onSearchInputChangedSubject = BehaviorSubject<String?>.seeded(null);

  Sink<String?> get onRefreshResultsRequest =>
      _onSearchInputChangedSubject.sink;

  List<Token>? get lastListingItems =>
      _onNewListingStateController.value.itemList;

  Sink<String?> get onSearchInputChangedSink =>
      _onSearchInputChangedSubject.sink;

  String? get _searchInputTerm => _onSearchInputChangedSubject.value;

  Stream<InfiniteScrollBlocListingState<Token>> _fetchList(int pageKey) async* {
    final lastListingState = _onNewListingStateController.value;
    try {
      final newItems = await getData(pageKey, _pageSize, _searchInputTerm);
      final isLastPage = newItems.length < _pageSize;
      final nextPageKey = isLastPage ? null : pageKey + 1;
      var allItems = <Token>[...lastListingState.itemList ?? [], ...newItems];
      allItems = filterItemsFunction(allItems);
      yield InfiniteScrollBlocListingState<Token>(
        nextPageKey: nextPageKey,
        itemList: allItems,
      );
    } catch (e, stackTrace) {
      Logger('TokenMapBloc').log(Level.WARNING, '_fetchList', e, stackTrace);
      yield InfiniteScrollBlocListingState<Token>(
        error: e,
        nextPageKey: lastListingState.nextPageKey,
        itemList: lastListingState.itemList,
      );
    }
  }

  void dispose() {
    _onSearchInputChangedSubject.close();
    _onNewListingStateController.close();
    _subscriptions.dispose();
    _onPageRequest.close();
  }

  List<Token> _sortTokenList(List<Token> tokens) {
    tokens = tokens.fold<List<Token>>(
      [],
      (previousValue, token) {
        if (![kZnnCoin.tokenStandard, kQsrCoin.tokenStandard]
            .contains(token.tokenStandard)) {
          previousValue.add(token);
        }
        return previousValue;
      },
    ).toList();
    tokens = _sortByIfTokenCreatedByUser(tokens);
    return _sortByIfTokenIsInFavorites(tokens);
  }

  List<Token> _sortByIfTokenCreatedByUser(List<Token> tokens) {
    final sortedTokens = tokens
        .where(
          (token) => kDefaultAddressList.contains(
            token.owner.toString(),
          ),
        )
        .toList();

    sortedTokens.addAll(tokens
        .where(
          (token) => !kDefaultAddressList.contains(
            token.owner.toString(),
          ),
        )
        .toList(),);

    return sortedTokens;
  }

  List<Token> _sortByIfTokenIsInFavorites(List<Token> tokens) {
    final favoriteTokens = Hive.box(kFavoriteTokensBox);

    final sortedTokens = tokens
        .where(
          (token) => favoriteTokens.values.contains(
            token.tokenStandard.toString(),
          ),
        )
        .toList();

    sortedTokens.addAll(tokens
        .where(
          (token) => !favoriteTokens.values.contains(
            token.tokenStandard.toString(),
          ),
        )
        .toList(),);

    return sortedTokens;
  }

  Future<List<Token>> getData(
    int pageKey,
    int pageSize,
    String? searchTerm,
  ) async {
    if (searchTerm == null || searchTerm.isEmpty) {
      return (await zenon!.embedded.token.getAll(
        pageIndex: pageKey,
        pageSize: pageSize,
      ))
          .list!;
    } else {
      return _getDataBySearchTerm(pageKey, pageSize, searchTerm);
    }
  }

  List<Token> Function(List<Token> p1) get filterItemsFunction =>
      _sortTokenList;

  Future<List<Token>> _getDataBySearchTerm(
    int pageKey,
    int pageSize,
    String searchTerm,
  ) async {
    _allTokens ??= (await zenon!.embedded.token.getAll()).list!;
    final results = _allTokens!.where((token) =>
        token.symbol.toLowerCase().contains(searchTerm.toLowerCase()),);
    results.toList().sublist(
          pageKey * pageSize,
          (pageKey + 1) * pageSize <= results.length
              ? (pageKey + 1) * pageSize
              : results.length,
        );
    return results
        .where((token) =>
            token.symbol.toLowerCase().contains(searchTerm.toLowerCase()),)
        .toList();
  }
}
