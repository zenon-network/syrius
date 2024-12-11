part of 'pillars_cubit.dart';

/// This state is used by the [PillarsCubit] to track and update the number of
/// active pillars.
///
/// [PillarsState] stores an integer value representing the number of pillars
/// retrieved from the Zenon network.
@JsonSerializable(explicitToJson: true)
class PillarsState extends TimerState<int> {
  /// Constructs a new [PillarsState] object.
  ///
  /// The [data] field in this case represents the count of active pillars on
  /// the Zenon network.
  const PillarsState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory PillarsState.fromJson(Map<String, dynamic> json) =>
      _$PillarsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<int> copyWith({
    TimerStatus? status,
    int? data,
    SyriusException? error,
  }) {
    return PillarsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarsStateToJson(this);
}
