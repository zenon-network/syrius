part of 'pillars_cubit.dart';

/// The state class for the `PillarsCubit`, extending `DashboardState` to
/// manage the data related to pillars.
///
/// `PillarsState` stores an integer value representing the number of pillars
/// retrieved from the Zenon network.
/// This state is used by the `PillarsCubit` to track and update the number of
/// active pillars.
@JsonSerializable()
class PillarsState extends TimerState<int> {
  /// Constructs a new `PillarsState`.
  ///
  /// This state is initialized with the default `status`, `data`, and `error`
  /// values from the parent `DashboardState` class.
  /// The `data` field in this case represents the count of active pillars on
  /// the Zenon network.
  const PillarsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [PillarsState] instance from a JSON map.
  factory PillarsState.fromJson(Map<String, dynamic> json) =>
      _$PillarsStateFromJson(json);

  /// Creates a copy of the current `PillarsState` with optional new values for
  /// `status`, `data`, and `error`.
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  ///
  /// Returns:
  /// - A new instance of `PillarsState` with the updated values or the
  /// existing ones if none are provided.
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
