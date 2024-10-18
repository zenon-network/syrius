part of 'pillars_cubit.dart';

/// The state class for the `PillarsCubit`, extending `DashboardState` to manage the data related to pillars.
///
/// `PillarsState` stores an integer value representing the number of pillars retrieved from the Zenon network.
/// This state is used by the `PillarsCubit` to track and update the number of active pillars.
class PillarsState extends DashboardState<int> {
  /// Constructs a new `PillarsState`.
  ///
  /// This state is initialized with the default `status`, `data`, and `error` values from the parent `DashboardState` class.
  /// The `data` field in this case represents the count of active pillars on the Zenon network.
  const PillarsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `PillarsState` with optional new values for `status`, `data`, and `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `PillarsState` with the updated values or the existing ones if none are provided.
  @override
  DashboardState<int> copyWith({
    CubitStatus? status,
    int? data,
    Object? error,
  }) {
    return PillarsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
