part of 'total_hourly_transactions_cubit.dart';

/// The state class for [TotalHourlyTransactionsCubit], which extends
/// [TimerState] to manage the hourly transaction count data.
///
/// This class manages a [Map<String, dynamic>] where the key-value pairs
/// represent transaction statistics (e.g., the number of account blocks and
/// the timestamp) for the last hour. It tracks the state of fetching
/// hourly transaction data within [TotalHourlyTransactionsCubit].
@JsonSerializable()
class TotalHourlyTransactionsState extends TimerState<int> {
  /// Constructs a new [TotalHourlyTransactionsState] with optional values for
  /// [status], [data], and [error].
  ///
  /// The [data] field holds a map containing the transaction statistics for
  /// the last hour.
  const TotalHourlyTransactionsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [TotalHourlyTransactionsState] instance from a JSON map.
  factory TotalHourlyTransactionsState.fromJson(Map<String, dynamic> json) =>
      _$TotalHourlyTransactionsStateFromJson(json);

  /// Creates a copy of the current [TotalHourlyTransactionsState] with updated
  /// values for [status], [data], or [error].
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of [TotalHourlyTransactionsState] with the updated
  /// values or the existing ones if none are provided.
  @override
  TimerState<int> copyWith({
    TimerStatus? status,
    int? data,
    SyriusException? error,
  }) {
    return TotalHourlyTransactionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [TotalHourlyTransactionsState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$TotalHourlyTransactionsStateToJson(this);
}