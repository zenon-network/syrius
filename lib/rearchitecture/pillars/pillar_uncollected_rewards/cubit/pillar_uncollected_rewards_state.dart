part of 'pillar_uncollected_rewards_cubit.dart';

/// The state representation of [PillarUncollectedRewardsCubit].
@JsonSerializable(explicitToJson: true)
class PillarUncollectedRewardsState extends IndicatorState<UncollectedReward> {
  /// Creates a new instance of [PillarUncollectedRewardsState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const PillarUncollectedRewardsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a new instance from a JSON object.
  factory PillarUncollectedRewardsState.fromJson(Map<String, dynamic> json) =>
      _$PillarUncollectedRewardsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<UncollectedReward> copyWith({
    IndicatorStatus? status,
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
