part of 'token_search_bloc.dart';

/// Base class for token search events.
sealed class TokenSearchEvent extends Equatable {
  const TokenSearchEvent();
}

/// Requests token results matching a symbol query.
final class TokenSearchRequested extends TokenSearchEvent {
  /// Creates a new instance.
  const TokenSearchRequested({
    required this._query,
    this._refresh = false,
  });

  final String _query;
  final bool _refresh;

  /// The symbol query entered by the user.
  String get query => _query;

  /// Whether the cached full token list should be fetched again.
  bool get refresh => _refresh;

  @override
  List<Object> get props => <Object>[_query, _refresh];
}

/// Requests the next page of matching tokens.
final class TokenSearchMoreRequested extends TokenSearchEvent {
  /// Creates a new instance.
  const TokenSearchMoreRequested();

  @override
  List<Object> get props => <Object>[];
}
