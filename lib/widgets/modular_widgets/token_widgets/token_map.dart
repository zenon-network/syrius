import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenMap extends StatefulWidget {
  const TokenMap({super.key});

  @override
  State createState() {
    return _TokenMapState();
  }
}

class _TokenMapState extends State<TokenMap> {
  final PagingController<int, Token> _pagingController = PagingController(
    firstPageKey: 0,
  );

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchKeyWordController =
      TextEditingController();

  final TokenMapBloc _bloc = TokenMapBloc();

  late StreamSubscription _blocListingStateSubscription;

  final StreamController<String> _textChangeStreamController =
      StreamController();
  late StreamSubscription _textChangesSubscription;

  @override
  void initState() {
    super.initState();
    _textChangesSubscription = _textChangeStreamController.stream
        .debounceTime(
          const Duration(seconds: 1),
        )
        .distinct()
        .listen((text) {
      _bloc.onSearchInputChangedSink.add(text);
    });
    _pagingController.addPageRequestListener((pageKey) {
      _bloc.onPageRequestSink.add(pageKey);
    });
    _blocListingStateSubscription = _bloc.onNewListingState.listen(
      (listingState) {
        _pagingController.value = PagingState(
          nextPageKey: listingState.nextPageKey,
          error: listingState.error,
          itemList: listingState.itemList,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Token Map',
      description: 'This card displays a grid with all the ZTS tokens '
          'from the network, including ZTS tokens issued by you',
      childBuilder: () => _getWidgetBody(_bloc),
      onRefreshPressed: () {
        _searchKeyWordController.clear();
        _bloc.refreshResults();
      },
    );
  }

  Widget _getWidgetBody(TokenMapBloc bloc) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          InputField(
            controller: _searchKeyWordController,
            hintText: 'Search token by symbol',
            suffixIcon: const Icon(
              Icons.search,
              color: Colors.green,
            ),
            onChanged: _textChangeStreamController.add,
          ),
          kVerticalSpacing,
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: PagedGridView(
                scrollController: _scrollController,
                pagingController: _pagingController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 100 / 80,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                ),
                builderDelegate: PagedChildBuilderDelegate<Token>(
                  itemBuilder: (_, token, __) => TokenCard(
                    token,
                    () {
                      bloc.refreshResults();
                    },
                  ),
                  firstPageProgressIndicatorBuilder: (_) =>
                      const SyriusLoadingWidget(),
                  newPageProgressIndicatorBuilder: (_) =>
                      const SyriusLoadingWidget(),
                  noMoreItemsIndicatorBuilder: (_) =>
                      const SyriusErrorWidget('No more items'),
                  noItemsFoundIndicatorBuilder: (_) =>
                      const SyriusErrorWidget('No items found'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textChangeStreamController.close();
    _textChangesSubscription.cancel();
    _scrollController.dispose();
    _pagingController.dispose();
    _bloc.dispose();
    _blocListingStateSubscription.cancel();
    super.dispose();
  }
}
