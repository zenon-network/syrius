// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_sentinels_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveSentinelsState _$ActiveSentinelsStateFromJson(
  Map<String, dynamic> json,
) => ActiveSentinelsState(
  status:
      $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
      TimerStatus.initial,
  data: json['data'] == null
      ? null
      : SentinelInfoList.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'] == null
      ? null
      : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ActiveSentinelsStateToJson(
  ActiveSentinelsState instance,
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
