// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillars_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarsState _$PillarsStateFromJson(Map<String, dynamic> json) => PillarsState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: (json['data'] as num?)?.toInt(),
      error: json['error'],
    );

Map<String, dynamic> _$PillarsStateToJson(PillarsState instance) =>
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
