part of 'search_token_bloc.dart';

/// Base class for states emitted while searching network tokens.
sealed class SearchTokenState extends Equatable {
  /// Creates a token search state for [_query].
  const SearchTokenState({required this._query});

  final String _query;

  /// The normalized search query represented by this state.
  String get query => _query;

  @override
  List<Object?> get props => <Object?>[_query];
}

/// Initial state when no token search is active.
final class SearchTokenInitial extends SearchTokenState {
  /// Creates the initial token search state.
  const SearchTokenInitial() : super(query: '');
}

/// Loading state while token search results are being prepared.
final class SearchTokenLoading extends SearchTokenState {
  /// Creates a loading token search state.
  const SearchTokenLoading({required super.query});
}

/// Failure state emitted when searching tokens fails.
final class SearchTokenFailure extends SearchTokenState {
  /// Creates a token search failure state.
  const SearchTokenFailure({
    required super.query,
    required this._exception,
  });

  final SyriusException _exception;

  /// The error that prevented tokens from being searched.
  SyriusException get exception => _exception;

  @override
  List<Object?> get props => <Object?>[...super.props, _exception];
}

/// Populated state containing every token matching the search query.
final class SearchTokenPopulated extends SearchTokenState {
  /// Creates a populated token search state.
  const SearchTokenPopulated({
    required super.query,
    required this._tokens,
  });

  final List<Token> _tokens;

  /// Every token matching the search query.
  List<Token> get tokens => _tokens;

  @override
  List<Object?> get props => <Object?>[...super.props, _tokens];
}
