part of 'pillar_uncollected_rewards_cubit.dart';

/// The state representation of [PillarUncollectedRewardsCubit].
@JsonSerializable(explicitToJson: true)
class PillarUncollectedRewardsState extends CubitWithRefreshMixinState<UncollectedReward> {
  /// Creates a new instance of [PillarUncollectedRewardsState].
  ///
  /// The [status] defaults to [CubitWithRefreshMixinStatus.initial].
  const PillarUncollectedRewardsState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory PillarUncollectedRewardsState.fromJson(Map<String, dynamic> json) =>
      _$PillarUncollectedRewardsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  CubitWithRefreshMixinState<UncollectedReward> copyWith({
    CubitWithRefreshMixinStatus? status,
    UncollectedReward? data,
    SyriusException? error,
  }) {
    return PillarUncollectedRewardsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarUncollectedRewardsStateToJson(this);

}
