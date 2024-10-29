part of 'delegation_cubit.dart';

/// The state class for the [DelegationCubit].
///
/// It holds a [DelegationInfo] object that represents the retrieved delegation
/// details.

@JsonSerializable(explicitToJson: true)
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

  /// {@macro state_copy_with}
  @override
  TimerState<DelegationInfo> copyWith({
    TimerStatus? status,
    DelegationInfo? data,
    CubitException? error,
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
