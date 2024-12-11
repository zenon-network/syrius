import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';

abstract class InfiniteScrollBloc<T> with RefreshBlocMixin {
  InfiniteScrollBloc({
    this.isDataRequestPaginated = true,
  }) {
    _onPageRequest.stream
        .flatMap(_fetchList)
        .listen(_onNewListingStateController.add)
        .addTo(_subscriptions);

    _onRefreshResultsRequest.stream
        .flatMap((_) => _doRefreshResults())
        .listen(_onNewListingStateController.add)
        .addTo(_subscriptions);

    listenToWsRestart(refreshResults);
  }

  final bool isDataRequestPaginated;

  List<T> Function(List<T>)? filterItemsFunction;

  Future<List<T>> getData(int pageKey, int pageSize);

  void refreshResults() {
    if (!_onRefreshResultsRequest.isClosed) {
      onRefreshResultsRequest.add(true);
    }
  }

  Stream<InfiniteScrollBlocListingState<T>> _doRefreshResults() async* {
    yield InfiniteScrollBlocListingState<T>();
    yield* _fetchList(0);
  }

  static const int _pageSize = 10;

  final CompositeSubscription _subscriptions = CompositeSubscription();

  final BehaviorSubject<InfiniteScrollBlocListingState<T>> _onNewListingStateController =
      BehaviorSubject<InfiniteScrollBlocListingState<T>>.seeded(
    InfiniteScrollBlocListingState<T>(),
  );

  Stream<InfiniteScrollBlocListingState<T>> get onNewListingState =>
      _onNewListingStateController.stream;

  final StreamController<int> _onPageRequest = StreamController<int>();
  final StreamController<bool> _onRefreshResultsRequest = StreamController<bool>();

  Sink<int> get onPageRequestSink => _onPageRequest.sink;

  Sink<bool> get onRefreshResultsRequest => _onRefreshResultsRequest.sink;

  List<T>? get lastListingItems => _onNewListingStateController.value.itemList;

  Stream<InfiniteScrollBlocListingState<T>> _fetchList(int pageKey) async* {
    final InfiniteScrollBlocListingState<T> lastListingState = _onNewListingStateController.value;
    try {
      final List<T> newItems = await getData(pageKey, _pageSize);
      final bool isLastPage = newItems.length < _pageSize || !isDataRequestPaginated;
      final int? nextPageKey = isLastPage ? null : pageKey + 1;
      List<T> allItems = isDataRequestPaginated
          ? <T>[...lastListingState.itemList ?? <T>[], ...newItems]
          : newItems;
      if (filterItemsFunction != null) {
        allItems = filterItemsFunction!(allItems);
      }
      yield InfiniteScrollBlocListingState<T>(
        nextPageKey: nextPageKey,
        itemList: allItems,
      );
    } catch (e, stackTrace) {
      Logger('InfiniteScrollBloc')
          .log(Level.WARNING, '_fetchList', e, stackTrace);
      yield InfiniteScrollBlocListingState<T>(
        error: e,
        nextPageKey: lastListingState.nextPageKey,
        itemList: lastListingState.itemList,
      );
    }
  }

  void dispose() {
    _onRefreshResultsRequest.close();
    _onNewListingStateController.close();
    _subscriptions.dispose();
    _onPageRequest.close();
  }
}

class InfiniteScrollBlocListingState<T> {
  InfiniteScrollBlocListingState({
    this.itemList,
    this.error,
    this.nextPageKey = 0,
  });

  final List<T>? itemList;
  final dynamic error;
  final int? nextPageKey;
}
