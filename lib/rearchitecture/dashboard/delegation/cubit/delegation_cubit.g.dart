// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationState _$DelegationStateFromJson(Map<String, dynamic> json) =>
    DelegationState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: json['data'] == null
          ? null
          : DelegationInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$DelegationStateToJson(DelegationState instance) =>
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
