part of 'active_pillars_cubit.dart';

/// This state is used by the [ActivePillarsCubit] to track and update the
/// number of active active_pillars.
///
/// [ActivePillarsState] stores an integer value representing the number of
/// active_pillars retrieved from the Zenon network.
@JsonSerializable(explicitToJson: true)
class ActivePillarsState extends TimerState<int> {
  /// Constructs a new [ActivePillarsState] object.
  ///
  /// The [data] field in this case represents the count of active
  /// active_pillars on the Zenon network.
  const ActivePillarsState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory ActivePillarsState.fromJson(Map<String, dynamic> json) =>
      _$ActivePillarsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<int> copyWith({
    TimerStatus? status,
    int? data,
    SyriusException? error,
  }) {
    return ActivePillarsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$ActivePillarsStateToJson(this);
}
