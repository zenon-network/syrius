part of 'token_search_bloc.dart';

/// Status of a token search operation.
enum TokenSearchStatus {
  /// No search is active.
  initial,

  /// Search results are being prepared.
  loading,

  /// Searching failed.
  failure,

  /// Search results are available.
  success,
}

/// State emitted by [TokenSearchBloc].
class TokenSearchState extends Equatable {
  /// Creates an initial state.
  const TokenSearchState.initial()
    : _status = TokenSearchStatus.initial,
      _query = '',
      _tokens = const <Token>[],
      _hasReachedMax = false,
      _error = null;

  /// Creates a loading state.
  const TokenSearchState.loading({required this._query})
    : _status = TokenSearchStatus.loading,
      _tokens = const <Token>[],
      _hasReachedMax = false,
      _error = null;

  /// Creates a failure state.
  const TokenSearchState.failure({
    required this._query,
    required SyriusException this._error,
  }) : _status = TokenSearchStatus.failure,
       _tokens = const <Token>[],
       _hasReachedMax = false;

  /// Creates a successful state.
  const TokenSearchState.success({
    required this._query,
    required this._tokens,
    required this._hasReachedMax,
  }) : _status = TokenSearchStatus.success,
       _error = null;

  final SyriusException? _error;
  final bool _hasReachedMax;
  final String _query;
  final TokenSearchStatus _status;
  final List<Token> _tokens;

  /// The error encountered while searching.
  SyriusException? get error => _error;

  /// Whether all matching tokens have been emitted.
  bool get hasReachedMax => _hasReachedMax;

  /// The normalized search query represented by this state.
  String get query => _query;

  /// The current search status.
  TokenSearchStatus get status => _status;

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
