part of 'delegation_stats_cubit.dart';

/// The state class for the [DelegationStatsCubit].
///
/// It holds a [DelegationInfo] object that represents the retrieved delegation_stats
/// details.

@JsonSerializable(explicitToJson: true)
class DelegationStatsState extends TimerState<DelegationInfo> {
  /// Constructs a new DelegationState object.
  ///
  /// This state is initialized with default [status], [data], and [error]
  /// values from the parent class.
  /// It manages delegation_stats information for an account.
  const DelegationStatsState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory DelegationStatsState.fromJson(Map<String, dynamic> json) =>
      _$DelegationStatsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<DelegationInfo> copyWith({
    TimerStatus? status,
    DelegationInfo? data,
    SyriusException? error,
  }) {
    return DelegationStatsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$DelegationStatsStateToJson(this);
}
