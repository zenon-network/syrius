part of 'tokens_cubit.dart';

/// A class that tells what is the status of fetching the available tokens
enum TokensStatus {
  /// Fetching failed
  failure,

  /// Fetching has not started
  initial,

  /// Fetching completed successfully
  success,
}

/// A class that defines the data hold to update the UI when it relies on
/// the available list of tokens
@JsonSerializable()
class TokensState extends Equatable {
  /// Creates a new constant instance.
  const TokensState({
    required this.status,
    this.error,
    this.data,
  });

  /// Creates a new instance with the [status] of [TokensState.initial]
  const TokensState.initial()
      : this(
          status: TokensStatus.initial,
        );

  /// {@macro state_from_json}
  factory TokensState.fromJson(Map<String, dynamic> json) =>
      _$TokensStateFromJson(json);

  /// Exception encountered while fetching the available tokens
  final SyriusException? error;

  /// The status of fetching the available tokens
  final TokensStatus status;

  /// The available tokens, in case fetching was successful
  final List<Token>? data;

  /// {@macro state_copy_with}
  TokensState copyWith({
    List<Token>? data,
    TokensStatus? status,
    SyriusException? error,
  }) =>
      TokensState(
        data: data ?? this.data,
        error: error ?? this.error,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => <Object?>[error, status, data];

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$TokensStateToJson(this);
}
