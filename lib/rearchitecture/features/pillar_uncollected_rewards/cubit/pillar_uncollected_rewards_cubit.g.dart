// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillar_uncollected_rewards_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarUncollectedRewardsState _$PillarUncollectedRewardsStateFromJson(
        Map<String, dynamic> json) =>
    PillarUncollectedRewardsState(
      status: $enumDecodeNullable(
              _$CubitWithRefreshMixinStatusEnumMap, json['status']) ??
          CubitWithRefreshMixinStatus.loading,
      data: json['data'] == null
          ? null
          : UncollectedReward.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PillarUncollectedRewardsStateToJson(
        PillarUncollectedRewardsState instance) =>
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
