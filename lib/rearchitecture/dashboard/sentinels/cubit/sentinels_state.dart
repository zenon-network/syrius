part of 'sentinels_cubit.dart';

/// The state class for `SentinelsCubit`, which extends `DashboardState` to manage sentinel-related data.
///
/// This class manages a `SentinelInfoList` object representing information about active sentinels. It is used to track
/// the state of sentinel data loading within the `SentinelsCubit`.
class SentinelsState extends DashboardState<SentinelInfoList> {
  /// Constructs a new `SentinelsState` with optional values for `status`, `data`, and `error`.
  ///
  /// The `data` field stores a `SentinelInfoList` object, which contains the details of all active sentinels on the network.
  const SentinelsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a copy of the current `SentinelsState` with updated values for `status`, `data`, or `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `SentinelsState` with the updated values or the existing ones if none are provided.
  @override
  DashboardState<SentinelInfoList> copyWith({
    CubitStatus? status,
    SentinelInfoList? data,
    Object? error,
  }) {
    return SentinelsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
