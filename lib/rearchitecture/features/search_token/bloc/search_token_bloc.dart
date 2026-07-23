import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'search_token_event.dart';

part 'search_token_state.dart';

/// Searches all network tokens by symbol and paginates the local results.
class SearchTokenBloc extends Bloc<SearchTokenEvent, SearchTokenState> {
  /// Creates a new instance.
  SearchTokenBloc({
    required this._zenon,
    this._pageSize = kPageSize,
    Duration debounceDuration = const Duration(milliseconds: 350),
  }) : super(const SearchTokenState.initial()) {
    on<SearchTokenRequested>(
      _onSearchRequested,
      transformer: _debounceRestartable(debounceDuration),
    );
    on<SearchTokenMoreRequested>(
      _onMoreRequested,
      transformer: droppable(),
    );
  }

  final Zenon _zenon;
  final int _pageSize;

  List<Token>? _allTokens;
  Future<List<Token>>? _allTokensRequest;
  List<Token> _matchingTokens = <Token>[];

  Future<void> _onSearchRequested(
    SearchTokenRequested event,
    Emitter<SearchTokenState> emit,
  ) async {
    final String query = event.query.trim();

    if (event.refresh) {
      _allTokens = null;
      _allTokensRequest = null;
    }

    if (query.isEmpty) {
      _matchingTokens = <Token>[];
      emit(const SearchTokenState.initial());
      return;
    }

    emit(SearchTokenState.loading(query: query));

    try {
      final List<Token> allTokens = await _getAllTokens();
      if (emit.isDone) return;

      final String normalizedQuery = query.toLowerCase();
      _matchingTokens = allTokens
          .where(
            (Token token) =>
                !<TokenStandard>{
                  kZnnCoin.tokenStandard,
                  kQsrCoin.tokenStandard,
                }.contains(token.tokenStandard) &&
                _matchesQuery(token, normalizedQuery),
          )
          .toList();

      final List<Token> firstPage = _matchingTokens.take(_pageSize).toList();

      emit(
        SearchTokenState.success(
          query: query,
          tokens: firstPage,
          hasReachedMax: firstPage.length == _matchingTokens.length,
        ),
      );
    } on SyriusException catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(SearchTokenState.failure(query: query, error: error));
    } on Object catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(
        SearchTokenState.failure(
          query: query,
          error: FailureException(),
        ),
      );
    }
  }

  void _onMoreRequested(
    SearchTokenMoreRequested _,
    Emitter<SearchTokenState> emit,
  ) {
    if (state.status != SearchTokenStatus.success || state.hasReachedMax) {
      return;
    }

    final int start = state.tokens.length;
    final int requestedEnd = start + _pageSize;
    final int end = requestedEnd < _matchingTokens.length
        ? requestedEnd
        : _matchingTokens.length;
    final List<Token> tokens = <Token>[
      ...state.tokens,
      ..._matchingTokens.sublist(start, end),
    ];

    emit(
      SearchTokenState.success(
        query: state.query,
        tokens: tokens,
        hasReachedMax: tokens.length == _matchingTokens.length,
      ),
    );
  }

  Future<List<Token>> _getAllTokens() async {
    final List<Token>? cachedTokens = _allTokens;
    if (cachedTokens != null) return cachedTokens;

    final Future<List<Token>> request = _allTokensRequest ??= _fetchAllTokens();

    try {
      final List<Token> tokens = await request;

      if (identical(_allTokensRequest, request)) {
        _allTokens = tokens;
        _allTokensRequest = null;
      }

      return tokens;
    } on Object {
      if (identical(_allTokensRequest, request)) {
        _allTokensRequest = null;
      }
      rethrow;
    }
  }

  Future<List<Token>> _fetchAllTokens() async {
    final TokenList tokenList = await _zenon.embedded.token.getAll();
    return tokenList.list ?? <Token>[];
  }

  bool _matchesQuery(Token token, String query) {
    return token.name.toLowerCase().contains(query) ||
        token.symbol.toLowerCase().contains(query) ||
        token.owner.toString().toLowerCase().contains(query) ||
        token.tokenStandard.toString().toLowerCase().contains(query);
  }
}

EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) {
    return restartable<E>().call(events.debounce(duration), mapper);
  };
}
