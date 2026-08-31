import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/all_tokens/all_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'search_token_event.dart';

part 'search_token_state.dart';

/// Searches all network tokens by name, symbol, owner, or token standard.
class SearchTokenBloc extends Bloc<SearchTokenEvent, SearchTokenState> {
  /// Creates a new instance.
  SearchTokenBloc({
    required this._zenon,
    Duration debounceDuration = const Duration(milliseconds: 350),
  }) : super(const SearchTokenInitial()) {
    on<SearchTokenRequested>(
      _onSearchRequested,
      transformer: _debounceRestartable(debounceDuration),
    );
  }

  final Zenon _zenon;

  List<Token>? _allTokens;
  Future<List<Token>>? _allTokensRequest;

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
      emit(const SearchTokenInitial());
      return;
    }

    emit(SearchTokenLoading(query: query));

    try {
      final List<Token> allTokens = await _getAllTokens();
      if (emit.isDone) return;

      final String normalizedQuery = query.toLowerCase();
      final List<Token> matchingTokens = allTokens
          .where(
            (Token token) =>
                !<TokenStandard>{
                  kZnnCoin.tokenStandard,
                  kQsrCoin.tokenStandard,
                }.contains(token.tokenStandard) &&
                _matchesQuery(token, normalizedQuery),
          )
          .toList();

      emit(
        SearchTokenPopulated(
          query: query,
          tokens: matchingTokens,
        ),
      );
    } on SyriusException catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(SearchTokenFailure(query: query, exception: error));
    } on Object catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(
        SearchTokenFailure(
          query: query,
          exception: FailureException(),
        ),
      );
    }
  }

  Future<List<Token>> _getAllTokens() async {
    final List<Token>? cachedTokens = _allTokens;
    if (cachedTokens != null) return cachedTokens;

    final Future<List<Token>> request = _allTokensRequest ??= fetchAllTokens(
      zenon: _zenon,
    );

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
