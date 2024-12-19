// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillar_rewards_history_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarRewardsHistoryState _$PillarRewardsHistoryStateFromJson(
        Map<String, dynamic> json) =>
    PillarRewardsHistoryState(
      status: $enumDecodeNullable(
              _$CubitWithRefreshMixinStatusEnumMap, json['status']) ??
          CubitWithRefreshMixinStatus.loading,
      data: json['data'] == null
          ? null
          : RewardHistoryList.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PillarRewardsHistoryStateToJson(
        PillarRewardsHistoryState instance) =>
    <String, dynamic>{
      'status': _$CubitWithRefreshMixinStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

const _$CubitWithRefreshMixinStatusEnumMap = {
  CubitWithRefreshMixinStatus.failure: 'failure',
  CubitWithRefreshMixinStatus.loading: 'loading',
  CubitWithRefreshMixinStatus.success: 'success',
};
