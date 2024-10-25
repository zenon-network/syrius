part of 'delegation_cubit.dart';

/// The state class for the `DelegationCubit`, extending `DashboardState` and managing delegation information.
///
/// `DelegationState` holds a `DelegationInfo` object that represents the current delegation details.
/// This state is used by the `DelegationCubit` to manage and track delegation-related data.
class DelegationState extends DashboardState<DelegationInfo> {
  /// Constructs a new `DelegationState`.
  ///
  /// This state is initialized with default `status`, `data`, and `error` values from the parent `DashboardState` class.
  /// It manages delegation information for an account.
  const DelegationState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `DelegationState` with optional new values for `status`, `data`, and `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `DelegationState` with the updated values or the existing ones if none are provided.
  @override
  DashboardState<DelegationInfo> copyWith({
    DashboardStatus? status,
    DelegationInfo? data,
    Object? error,
  }) {
    return DelegationState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
