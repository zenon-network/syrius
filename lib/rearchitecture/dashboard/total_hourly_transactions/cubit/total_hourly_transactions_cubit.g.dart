// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_hourly_transactions_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalHourlyTransactionsState _$TotalHourlyTransactionsStateFromJson(
        Map<String, dynamic> json) =>
    TotalHourlyTransactionsState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: (json['data'] as num?)?.toInt(),
      error: json['error'],
    );

Map<String, dynamic> _$TotalHourlyTransactionsStateToJson(
        TotalHourlyTransactionsState instance) =>
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
