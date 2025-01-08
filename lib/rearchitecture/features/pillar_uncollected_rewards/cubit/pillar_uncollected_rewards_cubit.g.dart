// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillar_uncollected_rewards_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarUncollectedRewardsState _$PillarUncollectedRewardsStateFromJson(
        Map<String, dynamic> json) =>
    PillarUncollectedRewardsState(
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      status: $enumDecodeNullable(
              _$CubitWithRefreshOptionStatusEnumMap, json['status']) ??
          CubitWithRefreshOptionStatus.loading,
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
      'address': instance.address?.toJson(),
      'status': _$CubitWithRefreshOptionStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

const _$CubitWithRefreshOptionStatusEnumMap = {
  CubitWithRefreshOptionStatus.failure: 'failure',
  CubitWithRefreshOptionStatus.loading: 'loading',
  CubitWithRefreshOptionStatus.success: 'success',
};
