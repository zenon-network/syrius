part of 'staking_cubit.dart';

/// The state class for `StakingCubit`, which extends `DashboardState` to manage staking-related data.
///
/// This class manages a `StakeList` object representing the list of active staking entries.
/// It tracks the loading, success, or failure of fetching staking data within the `StakingCubit`.
class StakingState extends DashboardState<StakeList> {
  /// Constructs a new `StakingState` with optional values for `status`, `data`, and `error`.
  ///
  /// The `data` field holds a `StakeList` object, which contains the list of active staking entries for a particular address.
  const StakingState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `StakingState` with updated values for `status`, `data`, or `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `StakingState`with the updated values or the existing ones if none are provided.
  @override
  DashboardState<StakeList> copyWith({
    CubitStatus? status,
    StakeList? data,
    Object? error,
  }) {
    return StakingState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
