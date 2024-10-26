// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentinels_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentinelsState _$SentinelsStateFromJson(Map<String, dynamic> json) =>
    SentinelsState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: json['data'] == null
          ? null
          : SentinelInfoList.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SentinelsStateToJson(SentinelsState instance) =>
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
