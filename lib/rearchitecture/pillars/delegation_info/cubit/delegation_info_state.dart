part of 'delegation_info_cubit.dart';

/// The state representation of [DelegationInfoCubit].
@JsonSerializable(explicitToJson: true)
class DelegationInfoState extends CubitWithRefreshMixinState<DelegationInfo> {
  /// Creates a new instance of [DelegationInfoState].
  ///
  /// The [status] defaults to [CubitWithRefreshMixinStatus.initial].
  const DelegationInfoState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory DelegationInfoState.fromJson(Map<String, dynamic> json) =>
      _$DelegationInfoStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  CubitWithRefreshMixinState<DelegationInfo> copyWith({
    CubitWithRefreshMixinStatus? status,
    DelegationInfo? data,
    SyriusException? error,
  }) {
    return DelegationInfoState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$DelegationInfoStateToJson(this);

}
