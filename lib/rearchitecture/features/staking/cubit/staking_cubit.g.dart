// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staking_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StakingState _$StakingStateFromJson(Map<String, dynamic> json) => StakingState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: json['data'] == null
          ? null
          : StakeList.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : CubitException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StakingStateToJson(StakingState instance) =>
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
