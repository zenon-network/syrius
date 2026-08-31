part of 'all_tokens_bloc.dart';

/// Base class for states emitted while retrieving network tokens.
sealed class AllTokensState extends Equatable {
  /// Creates a token state.
  const AllTokensState();

  /// Creates a token state from persisted JSON.
  factory AllTokensState.fromJson(Map<String, dynamic> json) {
    return switch (json['state']) {
      'failure' => AllTokensFailure(
        exception: SyriusException.fromJson(
          json['exception'] as Map<String, dynamic>,
        ),
      ),
      'initial' => const AllTokensInitial(),
      'populated' => AllTokensPopulated(
        data: (json['data'] as List<dynamic>)
            .map(
              (Object? token) => Token.fromJson(
                token! as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      _ => throw UnsupportedError('Unsupported all_tokens state'),
    };
  }

  /// Converts this state to JSON for persistence.
  Map<String, dynamic> toJson() {
    return switch (this) {
      AllTokensFailure(:final SyriusException exception) => <String, dynamic>{
        'state': 'failure',
        'exception': exception.toJson(),
      },
      AllTokensInitial() => <String, dynamic>{
        'state': 'initial',
      },
      AllTokensPopulated(:final List<Token> data) => <String, dynamic>{
        'state': 'populated',
        'data': data.map((Token token) => token.toJson()).toList(),
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before all tokens have been requested.
final class AllTokensInitial extends AllTokensState {
  /// Creates the initial token state.
  const AllTokensInitial();
}

/// Failure state emitted when retrieving all tokens fails.
final class AllTokensFailure extends AllTokensState {
  /// Creates a token failure state.
  const AllTokensFailure({required this.exception});

  /// The error that prevented all tokens from being retrieved.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}

/// Populated state containing every token available on the network.
final class AllTokensPopulated extends AllTokensState {
  /// Creates a populated token state.
  const AllTokensPopulated({required this.data});

  /// The available all tokens.
  final List<Token> data;

  @override
  List<Object?> get props => <Object?>[data];
}
