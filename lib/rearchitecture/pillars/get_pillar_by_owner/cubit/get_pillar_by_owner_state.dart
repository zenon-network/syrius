part of 'get_pillar_by_owner_cubit.dart';

/// The state representation of [GetPillarByOwnerCubit].
@JsonSerializable(explicitToJson: true)
class GetPillarByOwnerState extends IndicatorState<List<PillarInfo>> {
  /// Creates a new instance of [GetPillarByOwnerState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const GetPillarByOwnerState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a new instance from a JSON object.
  factory GetPillarByOwnerState.fromJson(Map<String, dynamic> json) =>
      _$GetPillarByOwnerStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<List<PillarInfo>> copyWith({
    IndicatorStatus? status,
    List<PillarInfo>? data,
    SyriusException? error,
  }) {
    return GetPillarByOwnerState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$GetPillarByOwnerStateToJson(this);

}
