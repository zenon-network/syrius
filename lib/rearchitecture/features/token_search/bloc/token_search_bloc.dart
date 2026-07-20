import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'token_search_event.dart';

part 'token_search_state.dart';

/// Searches all network tokens by symbol and paginates the local results.
class TokenSearchBloc extends Bloc<TokenSearchEvent, TokenSearchState> {
  /// Creates a new instance.
  TokenSearchBloc({
    required this._zenon,
    this._pageSize = kPageSize,
    Duration debounceDuration = const Duration(milliseconds: 350),
  }) : super(const TokenSearchState.initial()) {
    on<TokenSearchRequested>(
      _onSearchRequested,
      transformer: _debounceRestartable(debounceDuration),
    );
    on<TokenSearchMoreRequested>(
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
    TokenSearchRequested event,
    Emitter<TokenSearchState> emit,
  ) async {
    final String query = event.query.trim();

    if (event.refresh) {
      _allTokens = null;
      _allTokensRequest = null;
    }

    if (query.isEmpty) {
      _matchingTokens = <Token>[];
      emit(const TokenSearchState.initial());
      return;
    }

    emit(TokenSearchState.loading(query: query));

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
                token.symbol.toLowerCase().contains(normalizedQuery),
          )
          .toList();

      final List<Token> firstPage = _matchingTokens.take(_pageSize).toList();

      emit(
        TokenSearchState.success(
          query: query,
          tokens: firstPage,
          hasReachedMax: firstPage.length == _matchingTokens.length,
        ),
      );
    } on SyriusException catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(TokenSearchState.failure(query: query, error: error));
    } on Object catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(
        TokenSearchState.failure(
          query: query,
          error: FailureException(),
        ),
      );
    }
  }

  void _onMoreRequested(
    TokenSearchMoreRequested _,
    Emitter<TokenSearchState> emit,
  ) {
    if (state.status != TokenSearchStatus.success || state.hasReachedMax) {
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
      TokenSearchState.success(
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
}

EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) {
    return restartable<E>().call(events.debounce(duration), mapper);
  };
}
