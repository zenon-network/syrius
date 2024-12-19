part of 'pillar_rewards_history_cubit.dart';

/// The state representation of [PillarRewardsHistoryCubit].
@JsonSerializable(explicitToJson: true)
class PillarRewardsHistoryState
    extends CubitWithRefreshMixinState<RewardHistoryList> {
  /// Creates a new instance of [PillarRewardsHistoryState].
  ///
  /// The [status] defaults to [CubitWithRefreshMixinStatus.loading].
  const PillarRewardsHistoryState({
    super.status = CubitWithRefreshMixinStatus.loading,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory PillarRewardsHistoryState.fromJson(Map<String, dynamic> json) =>
      _$PillarRewardsHistoryStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  CubitWithRefreshMixinState<RewardHistoryList> copyWith({
    CubitWithRefreshMixinStatus? status,
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
