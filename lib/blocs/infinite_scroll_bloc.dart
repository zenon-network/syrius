import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/utils/logger.dart';

abstract class InfiniteScrollBloc<T> with RefreshBlocMixin {
  InfiniteScrollBloc() {
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

  static const _pageSize = 10;

  final _subscriptions = CompositeSubscription();

  final _onNewListingStateController =
      BehaviorSubject<InfiniteScrollBlocListingState<T>>.seeded(
    InfiniteScrollBlocListingState<T>(),
  );

  Stream<InfiniteScrollBlocListingState<T>> get onNewListingState =>
      _onNewListingStateController.stream;

  final _onPageRequest = StreamController<int>();
  final _onRefreshResultsRequest = StreamController<bool>();

  Sink<int> get onPageRequestSink => _onPageRequest.sink;
  Sink<bool> get onRefreshResultsRequest => _onRefreshResultsRequest.sink;

  List<T>? get lastListingItems => _onNewListingStateController.value.itemList;

  Stream<InfiniteScrollBlocListingState<T>> _fetchList(int pageKey) async* {
    final lastListingState = _onNewListingStateController.value;
    try {
      final newItems = await getData(pageKey, _pageSize);
      final isLastPage = newItems.length < _pageSize;
      final nextPageKey = isLastPage ? null : pageKey + 1;
      List<T> allItems = [...lastListingState.itemList ?? [], ...newItems];
      if (filterItemsFunction != null) {
        allItems = filterItemsFunction!(allItems);
      }
      yield InfiniteScrollBlocListingState<T>(
        error: null,
        nextPageKey: nextPageKey,
        itemList: allItems,
      );
    } catch (e) {
      Logger.logError(e);
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
