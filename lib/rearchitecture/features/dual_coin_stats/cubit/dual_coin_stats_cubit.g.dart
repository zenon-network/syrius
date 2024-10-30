// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dual_coin_stats_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DualCoinStatsState _$DualCoinStatsStateFromJson(Map<String, dynamic> json) =>
    DualCoinStatsState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Token.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DualCoinStatsStateToJson(DualCoinStatsState instance) =>
    <String, dynamic>{
      'status': _$TimerStatusEnumMap[instance.status]!,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'error': instance.error?.toJson(),
    };

const _$TimerStatusEnumMap = {
  TimerStatus.failure: 'failure',
  TimerStatus.initial: 'initial',
  TimerStatus.loading: 'loading',
  TimerStatus.success: 'success',
};
