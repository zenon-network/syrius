part of 'infinite_list_bloc.dart';

/// Represents the possible statuses for the latest transactions operation.
enum InfiniteListStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for the latest transactions, including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true, genericArgumentFactories: true)
class InfiniteListState<T> extends Equatable {
  /// Creates a new instance of LatestTransactionsState.
  ///
  /// The [status] defaults to [InfiniteListStatus.initial].
  const InfiniteListState({
    required this.status,
    this.data,
    this.error,
    this.hasReachedMax = false,
  });

  InfiniteListState.initial()
      : this(
          status: InfiniteListStatus.initial,
        );

  /// Creates a new instance from a JSON object.
  factory InfiniteListState.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$InfiniteListStateFromJson(json, fromJsonT);

  /// The current status of the latest transactions operation.
  final InfiniteListStatus status;

  /// The list of [AccountBlock] instances representing the latest transactions.
  ///
  /// It is populated when the [status] is [InfiniteListStatus.success].
  final List<T>? data;

  /// An object representing any error that occurred during data fetching.
  ///
  /// This is typically an exception or error message. It is populated when
  /// the [status] is [InfiniteListStatus.failure].
  final SyriusException? error;

  /// Whether there are more account blocks to be fetched.
  final bool hasReachedMax;

  ///{@macro state_copy_with}
  InfiniteListState<T> copyWith({
    InfiniteListStatus? status,
    List<T>? data,
    SyriusException? error,
    bool? hasReachedMax,
  }) {
    return InfiniteListState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  /// {@template state_to_json}
  /// Converts this state into a JSON map for persistence.
  ///
  /// This is used during serialization to save the state across app restarts.
  /// {@endtemplate}
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$InfiniteListStateToJson(
        this,
        toJsonT,
      );

  @override
  List<Object?> get props => <Object?>[status, data, error, hasReachedMax];
}
