part of 'all_tokens_bloc.dart';

/// Base class for token-list events.
sealed class AllTokensEvent extends Equatable {
  const AllTokensEvent();
}

/// Requests all tokens available on the network.
final class AllTokensRequested extends AllTokensEvent {
  /// Creates a request for all available tokens.
  const AllTokensRequested();

  @override
  List<Object?> get props => <Object?>[];
}
