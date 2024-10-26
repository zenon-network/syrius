// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dual_coin_stats_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DualCoinStatsState _$DualCoinStatsStateFromJson(Map<String, dynamic> json) =>
    DualCoinStatsState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Token.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$DualCoinStatsStateToJson(DualCoinStatsState instance) =>
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
