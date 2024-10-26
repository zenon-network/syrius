// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_statistics_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealtimeStatisticsState _$RealtimeStatisticsStateFromJson(
        Map<String, dynamic> json) =>
    RealtimeStatisticsState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AccountBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$RealtimeStatisticsStateToJson(
        RealtimeStatisticsState instance) =>
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
