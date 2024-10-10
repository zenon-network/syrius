part of 'balance_cubit.dart';

/// The state class for the `BalanceCubit`, extending `DashboardState` and managing account balance data.
///
/// `BalanceState` holds a map of account addresses to their corresponding `AccountInfo` objects.
/// This state is used by the `BalanceCubit` to track the balance information for multiple addresses.
class BalanceState extends DashboardState<Map<String, AccountInfo>> {
  /// Constructs a new `BalanceState`.
  ///
  /// This state uses the default `status`, `data`, and `error` from the parent `DashboardState` class
  /// and initializes them for managing balance data.
  BalanceState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `BalanceState` with optional new values for `status`, `data`, and `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `BalanceState` with the updated values or the existing ones if none are provided.
  @override
  DashboardState<Map<String, AccountInfo>> copyWith({
    CubitStatus? status,
    Map<String, AccountInfo>? data,
    Object? error,
  }) {
    return BalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
