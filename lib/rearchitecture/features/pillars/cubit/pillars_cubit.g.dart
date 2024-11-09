// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillars_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarsState _$PillarsStateFromJson(Map<String, dynamic> json) => PillarsState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: (json['data'] as num?)?.toInt(),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PillarsStateToJson(PillarsState instance) =>
    <String, dynamic>{
      'status': _$TimerStatusEnumMap[instance.status]!,
      'data': instance.data,
      'error': instance.error?.toJson(),
    };

const _$TimerStatusEnumMap = {
  TimerStatus.failure: 'failure',
  TimerStatus.initial: 'initial',
  TimerStatus.loading: 'loading',
  TimerStatus.success: 'success',
};
