part of 'search_token_bloc.dart';

/// Base class for token search events.
sealed class SearchTokenEvent extends Equatable {
  const SearchTokenEvent();
}

/// Requests token results matching a symbol query.
final class SearchTokenRequested extends SearchTokenEvent {
  /// Creates a new instance.
  const SearchTokenRequested({
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
