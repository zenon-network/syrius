part of 'latest_transactions_bloc.dart';

/// Represents the possible statuses for the latest transactions operation.
enum LatestTransactionsStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for the latest transactions, including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class LatestTransactionsState extends Equatable {
  /// Creates a new instance of LatestTransactionsState.
  ///
  /// The [status] defaults to [LatestTransactionsStatus.initial].
  const LatestTransactionsState({
    this.status = LatestTransactionsStatus.initial,
    this.data = const <AccountBlock>[],
    this.error,
    this.hasReachedMax = false,
  });

  /// Creates a new instance from a JSON object.
  factory LatestTransactionsState.fromJson(Map<String, dynamic> json) =>
      _$LatestTransactionsStateFromJson(json);

  /// The current status of the latest transactions operation.
  final LatestTransactionsStatus status;

  /// The list of [AccountBlock] instances representing the latest transactions.
  ///
  /// It is populated when the [status] is [LatestTransactionsStatus.success].
  final List<AccountBlock> data;

  /// An object representing any error that occurred during data fetching.
  ///
  /// This is typically an exception or error message. It is populated when
  /// the [status] is [LatestTransactionsStatus.failure].
  final SyriusException? error;

  /// Whether there are more account blocks to be fetched.
  final bool hasReachedMax;

  ///{@macro state_copy_with}
  LatestTransactionsState copyWith({
    LatestTransactionsStatus? status,
    List<AccountBlock>? data,
    SyriusException? error,
    bool? hasReachedMax,
  }) {
    return LatestTransactionsState(
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
  Map<String, dynamic> toJson() => _$LatestTransactionsStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}