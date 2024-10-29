part of 'staking_cubit.dart';

/// The state class for [StakingCubit], which extends [TimerState] to
/// manage staking-related data.
///
/// This class manages a [StakeList] object representing the list of active
/// staking entries.
/// It tracks the loading, success, or failure of fetching staking data within
/// the [StakingCubit].
@JsonSerializable()
class StakingState extends TimerState<StakeList> {
  /// Constructs a new [StakingState] with optional values for [status],
  /// [data], and [error].
  ///
  /// The [data] field holds a [StakeList] object, which contains the list of
  /// active staking entries for a particular address.
  const StakingState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [StakingState] instance from a JSON map.
  factory StakingState.fromJson(Map<String, dynamic> json) =>
      _$StakingStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<StakeList> copyWith({
    TimerStatus? status,
    StakeList? data,
    CubitException? error,
  }) {
    return StakingState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [StakingState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$StakingStateToJson(this);
}
