// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_stats_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationStatsState _$DelegationStatsStateFromJson(
  Map<String, dynamic> json,
) => DelegationStatsState(
  status:
      $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
      TimerStatus.initial,
  data: json['data'] == null
      ? null
      : DelegationInfo.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'] == null
      ? null
      : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DelegationStatsStateToJson(
  DelegationStatsState instance,
) => <String, dynamic>{
  'status': _$TimerStatusEnumMap[instance.status]!,
  'data': instance.data?.toJson(),
  'error': instance.error?.toJson(),
};

const _$TimerStatusEnumMap = {
  TimerStatus.failure: 'failure',
  TimerStatus.initial: 'initial',
  TimerStatus.loading: 'loading',
  TimerStatus.success: 'success',
};
