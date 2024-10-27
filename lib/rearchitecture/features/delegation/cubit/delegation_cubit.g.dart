// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationState _$DelegationStateFromJson(Map<String, dynamic> json) =>
    DelegationState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: json['data'] == null
          ? null
          : DelegationInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DelegationStateToJson(DelegationState instance) =>
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
