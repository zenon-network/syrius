// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BalanceState _$BalanceStateFromJson(Map<String, dynamic> json) => BalanceState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: json['data'] == null
          ? null
          : AccountInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$BalanceStateToJson(BalanceState instance) =>
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
