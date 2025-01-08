part of 'get_pillar_by_owner_cubit.dart';

/// The state representation of [GetPillarByOwnerCubit].
@JsonSerializable(explicitToJson: true)
class GetPillarByOwnerState
    extends CubitWithRefreshOptionState<List<PillarInfo>> {
  /// Creates a new instance of [GetPillarByOwnerState].
  ///
  /// The [status] defaults to [CubitWithRefreshOptionStatus.loading].
  const GetPillarByOwnerState({
    super.address,
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory GetPillarByOwnerState.fromJson(Map<String, dynamic> json) =>
      _$GetPillarByOwnerStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  CubitWithRefreshOptionState<List<PillarInfo>> copyWith({
    Address? address,
    CubitWithRefreshOptionStatus? status,
    List<PillarInfo>? data,
    SyriusException? error,
  }) {
    return GetPillarByOwnerState(
      address: address ?? this.address,
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$GetPillarByOwnerStateToJson(this);
}
