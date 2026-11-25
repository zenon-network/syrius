// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_general_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsGeneralState _$SettingsGeneralStateFromJson(
  Map<String, dynamic> json,
) => SettingsGeneralState(
  status:
      $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
      TimerStatus.initial,
  data: json['data'] == null
      ? null
      : SettingsGeneralData.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'] == null
      ? null
      : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SettingsGeneralStateToJson(
  SettingsGeneralState instance,
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
