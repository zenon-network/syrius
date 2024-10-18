part of 'realtime_statistics_cubit.dart';

/// The state class for `RealtimeStatisticsCubit`, which extends `DashboardState` to handle real-time statistics data.
///
/// This class manages a list of `AccountBlock` objects representing real-time blockchain data, such as recent transactions.
/// It's used to track the state of the data loading process in the `RealtimeStatisticsCubit`.
class RealtimeStatisticsState extends DashboardState<List<AccountBlock>> {
  /// Constructs a new `RealtimeStatisticsState` with optional values for `status`, `data`, and `error`.
  ///
  /// The `data` field stores a list of `AccountBlock` objects that represent real-time blockchain statistics.
  const RealtimeStatisticsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `RealtimeStatisticsState` with updated values for `status`, `data`, or `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `RealtimeStatisticsState` with the updated values or the existing ones if none are provided.
  @override
  DashboardState<List<AccountBlock>> copyWith({
    CubitStatus? status,
    List<AccountBlock>? data,
    Object? error,
  }) {
    return RealtimeStatisticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
