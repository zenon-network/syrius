// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_hourly_transactions_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalHourlyTransactionsState _$TotalHourlyTransactionsStateFromJson(
        Map<String, dynamic> json) =>
    TotalHourlyTransactionsState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: (json['data'] as num?)?.toInt(),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TotalHourlyTransactionsStateToJson(
        TotalHourlyTransactionsState instance) =>
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
