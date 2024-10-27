part of 'delegation_cubit.dart';

/// The state class for the [DelegationCubit].
///
/// It holds a [DelegationInfo] object that represents the retrieved delegation
/// details.

@JsonSerializable()
class DelegationState extends TimerState<DelegationInfo> {
  /// Constructs a new DelegationState object.
  ///
  /// This state is initialized with default [status], [data], and [error]
  /// values from the parent class.
  /// It manages delegation information for an account.
  const DelegationState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [DelegationState] instance from a JSON map.
  factory DelegationState.fromJson(Map<String, dynamic> json) =>
      _$DelegationStateFromJson(json);

  /// Creates a copy of the current [DelegationState] with optional new values
  /// for [status], [data], and [error].
  ///
  /// This method is used to create a new state with updated fields if provided,
  /// otherwise retaining the existing values.
  @override
  TimerState<DelegationInfo> copyWith({
    TimerStatus? status,
    DelegationInfo? data,
    SyriusException? error,
  }) {
    return DelegationState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [DelegationState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$DelegationStateToJson(this);
}
