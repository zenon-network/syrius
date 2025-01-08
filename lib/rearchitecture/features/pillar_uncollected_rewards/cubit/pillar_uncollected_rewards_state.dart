part of 'pillar_uncollected_rewards_cubit.dart';

/// The state representation of [PillarUncollectedRewardsCubit].
@JsonSerializable(explicitToJson: true)
class PillarUncollectedRewardsState
    extends CubitWithRefreshOptionState<UncollectedReward> {
  /// Creates a new instance of [PillarUncollectedRewardsState].
  ///
  /// The [status] defaults to [CubitWithRefreshOptionStatus.loading].
  const PillarUncollectedRewardsState({
    super.address,
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory PillarUncollectedRewardsState.fromJson(Map<String, dynamic> json) =>
      _$PillarUncollectedRewardsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  CubitWithRefreshOptionState<UncollectedReward> copyWith({
    Address? address,
    CubitWithRefreshOptionStatus? status,
    UncollectedReward? data,
    SyriusException? error,
  }) {
    return PillarUncollectedRewardsState(
      address: address ?? this.address,
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarUncollectedRewardsStateToJson(this);
}
