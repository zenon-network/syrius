part of 'balance_cubit.dart';

/// The class used by the [BalanceCubit] to send state updates to the
/// listening widgets.
///
/// The data hold, when the status is [DashboardStatus.success] is of type
/// [AccountInfo].

class BalanceState extends DashboardState<AccountInfo> {
  /// Constructs a new BalanceState.
  ///
  /// This state uses the default [status], [data], and [error] from the parent
  /// [DashboardState] class
  const BalanceState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current [BalanceState] with optional new values for
  /// [status], [data], and [error].
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of [BalanceState] with the updated values or the
  /// existing ones if none are provided.
  @override
  DashboardState<AccountInfo> copyWith({
    DashboardStatus? status,
    AccountInfo? data,
    Object? error,
  }) {
    return BalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
