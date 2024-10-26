// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staking_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StakingState _$StakingStateFromJson(Map<String, dynamic> json) => StakingState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: json['data'] == null
          ? null
          : StakeList.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$StakingStateToJson(StakingState instance) =>
    <String, dynamic>{
      'status': _$DashboardStatusEnumMap[instance.status]!,
      'data': instance.data,
      'error': instance.error,
    };

const _$DashboardStatusEnumMap = {
  DashboardStatus.failure: 'failure',
  DashboardStatus.initial: 'initial',
  DashboardStatus.loading: 'loading',
  DashboardStatus.success: 'success',
};
