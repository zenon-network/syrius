part of 'dual_coin_stats_cubit.dart';

/// The state class for the `DualCoinStatsCubit`, extending `DashboardState` to manage data related to ZNN and QSR.
///
/// `DualCoinStatsState` stores a list of `Token?` objects representing data for two tokens.
/// This state is used by the `DualCoinStatsCubit` to track and update the state of both tokens.
class DualCoinStatsState extends DashboardState<List<Token>> {
  /// Constructs a new `DualCoinStatsState`.
  ///
  /// This state is initialized with default `status`, `data`, and `error` values from the parent `DashboardState` class.
  /// It manages a list of `Token?` objects that represent the two tokens' data.
  const DualCoinStatsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `DualCoinStatsState` with optional new values for `status`, `data`, and `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `DualCoinStatsState` with the updated values or the existing ones if none are provided.
  @override
  DashboardState<List<Token>> copyWith({
    CubitStatus? status,
    List<Token>? data,
    Object? error,
  }) {
    return DualCoinStatsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
