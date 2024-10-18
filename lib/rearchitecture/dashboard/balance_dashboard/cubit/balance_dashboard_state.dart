part of 'balance_dashboard_cubit.dart';

/// The state class for the `BalanceDashboardCubit`, extending `DashboardState` and managing detailed account balance data.
///
/// `BalanceDashboardState` holds an `AccountInfo` object representing the balance information of a single account.
/// This state is used by the `BalanceDashboardCubit` to track detailed balance data.
class BalanceDashboardState extends DashboardState<AccountInfo> {
  /// Constructs a new `BalanceDashboardState`.
  ///
  /// This state uses the default `status`, `data`, and `error` from the parent `DashboardState` class,
  /// and initializes them to manage the detailed account balance.
  const BalanceDashboardState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `BalanceDashboardState` with optional new values for `status`, `data`, and `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `BalanceDashboardState` with updated values or the current ones if none are provided.
  @override
  DashboardState<AccountInfo> copyWith({
    CubitStatus? status,
    AccountInfo? data,
    Object? error,
  }) {
    return BalanceDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
