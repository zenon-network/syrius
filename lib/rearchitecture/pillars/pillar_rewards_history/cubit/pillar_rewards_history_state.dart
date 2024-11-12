part of 'pillar_rewards_history_cubit.dart';

/// The state representation of [PillarRewardsHistoryCubit].
@JsonSerializable(explicitToJson: true)
class PillarRewardsHistoryState extends IndicatorState<RewardHistoryList> {
  /// Creates a new instance of [PillarRewardsHistoryState].
  ///
  /// The [status] defaults to [IndicatorStatus.initial].
  const PillarRewardsHistoryState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a new instance from a JSON object.
  factory PillarRewardsHistoryState.fromJson(Map<String, dynamic> json) =>
      _$PillarRewardsHistoryStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  IndicatorState<RewardHistoryList> copyWith({
    IndicatorStatus? status,
    RewardHistoryList? data,
    SyriusException? error,
  }) {
    return PillarRewardsHistoryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarRewardsHistoryStateToJson(this);

}
