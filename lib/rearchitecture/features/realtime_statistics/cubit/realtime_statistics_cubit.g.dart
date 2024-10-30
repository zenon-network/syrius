// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_statistics_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealtimeStatisticsState _$RealtimeStatisticsStateFromJson(
        Map<String, dynamic> json) =>
    RealtimeStatisticsState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AccountBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RealtimeStatisticsStateToJson(
        RealtimeStatisticsState instance) =>
    <String, dynamic>{
      'status': _$TimerStatusEnumMap[instance.status]!,
      'data': instance.data,
      'error': instance.error,
    };

const _$TimerStatusEnumMap = {
  TimerStatus.failure: 'failure',
  TimerStatus.initial: 'initial',
  TimerStatus.loading: 'loading',
  TimerStatus.success: 'success',
};
