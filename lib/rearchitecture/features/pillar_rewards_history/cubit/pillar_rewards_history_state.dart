part of 'pillar_rewards_history_cubit.dart';

/// The state representation of [PillarRewardsHistoryCubit].
@JsonSerializable(explicitToJson: true)
class PillarRewardsHistoryState
    extends CubitWithRefreshOptionState<RewardHistoryList> {
  /// Creates a new instance of [PillarRewardsHistoryState].
  ///
  /// The [status] defaults to [CubitWithRefreshOptionStatus.loading].
  const PillarRewardsHistoryState({
    super.address,
    super.status = CubitWithRefreshOptionStatus.loading,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory PillarRewardsHistoryState.fromJson(Map<String, dynamic> json) =>
      _$PillarRewardsHistoryStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  CubitWithRefreshOptionState<RewardHistoryList> copyWith({
    Address? address,
    CubitWithRefreshOptionStatus? status,
    RewardHistoryList? data,
    SyriusException? error,
  }) {
    return PillarRewardsHistoryState(
      address: address ?? this.address,
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarRewardsHistoryStateToJson(this);
}
