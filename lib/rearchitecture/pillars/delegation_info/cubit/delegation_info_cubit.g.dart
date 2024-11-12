// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_info_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationInfoState _$DelegationInfoStateFromJson(Map<String, dynamic> json) =>
    DelegationInfoState(
      status: $enumDecodeNullable(_$IndicatorStatusEnumMap, json['status']) ??
          IndicatorStatus.initial,
      data: json['data'] == null
          ? null
          : DelegationInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DelegationInfoStateToJson(
        DelegationInfoState instance) =>
    <String, dynamic>{
      'status': _$IndicatorStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

const _$IndicatorStatusEnumMap = {
  IndicatorStatus.failure: 'failure',
  IndicatorStatus.initial: 'initial',
  IndicatorStatus.loading: 'loading',
  IndicatorStatus.success: 'success',
};
