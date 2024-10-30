part of 'pillars_cubit.dart';

/// This state is used by the [PillarsCubit] to track and update the number of
/// active pillars.
///
/// [PillarsState] stores an integer value representing the number of pillars
/// retrieved from the Zenon network.
@JsonSerializable()
class PillarsState extends TimerState<int> {
  /// Constructs a new [PillarsState] object.
  ///
  /// This state is initialized with the default [status], [data], and [error]
  /// values from the parent [TimerState] class.
  /// The [data] field in this case represents the count of active pillars on
  /// the Zenon network.
  const PillarsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [PillarsState] instance from a JSON map.
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

  /// Converts this [PillarsState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$PillarsStateToJson(this);
}
