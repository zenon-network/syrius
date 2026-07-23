part of 'search_token_bloc.dart';

/// Status of a token search operation.
enum SearchTokenStatus {
  /// No search is active.
  initial,

  /// Search results are being prepared.
  loading,

  /// Searching failed.
  failure,

  /// Search results are available.
  success,
}

/// State emitted by [SearchTokenBloc].
class SearchTokenState extends Equatable {
  /// Creates an initial state.
  const SearchTokenState.initial()
    : _status = SearchTokenStatus.initial,
      _query = '',
      _tokens = const <Token>[],
      _hasReachedMax = false,
      _error = null;

  /// Creates a loading state.
  const SearchTokenState.loading({required this._query})
    : _status = SearchTokenStatus.loading,
      _tokens = const <Token>[],
      _hasReachedMax = false,
      _error = null;

  /// Creates a failure state.
  const SearchTokenState.failure({
    required this._query,
    required SyriusException this._error,
  }) : _status = SearchTokenStatus.failure,
       _tokens = const <Token>[],
       _hasReachedMax = false;

  /// Creates a successful state.
  const SearchTokenState.success({
    required this._query,
    required this._tokens,
    required this._hasReachedMax,
  }) : _status = SearchTokenStatus.success,
       _error = null;

  final SyriusException? _error;
  final bool _hasReachedMax;
  final String _query;
  final SearchTokenStatus _status;
  final List<Token> _tokens;

  /// The error encountered while searching.
  SyriusException? get error => _error;

  /// Whether all matching tokens have been emitted.
  bool get hasReachedMax => _hasReachedMax;

  /// The normalized search query represented by this state.
  String get query => _query;

  /// The current search status.
  SearchTokenStatus get status => _status;

  /// The currently emitted page of matching tokens.
  List<Token> get tokens => _tokens;

  @override
  List<Object?> get props => <Object?>[
    _status,
    _query,
    _tokens,
    _hasReachedMax,
    _error,
  ];
}
