// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillar_uncollected_rewards_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarUncollectedRewardsState _$PillarUncollectedRewardsStateFromJson(
        Map<String, dynamic> json) =>
    PillarUncollectedRewardsState(
      status: $enumDecodeNullable(_$IndicatorStatusEnumMap, json['status']) ??
          IndicatorStatus.initial,
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
      'status': _$IndicatorStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

const _$IndicatorStatusEnumMap = {
  IndicatorStatus.failure: 'failure',
  IndicatorStatus.initial: 'initial',
  IndicatorStatus.loading: 'loading',
  IndicatorStatus.success: 'success',
};
