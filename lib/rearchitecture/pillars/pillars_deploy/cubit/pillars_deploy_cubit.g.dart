// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillars_deploy_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarsDeployState _$PillarsDeployStateFromJson(Map<String, dynamic> json) =>
    PillarsDeployState(
      status:
          $enumDecodeNullable(_$PillarsDeployStatusEnumMap, json['status']) ??
              PillarsDeployStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$PillarsDeployStateToJson(PillarsDeployState instance) =>
    <String, dynamic>{
      'status': _$PillarsDeployStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$PillarsDeployStatusEnumMap = {
  PillarsDeployStatus.initial: 'initial',
  PillarsDeployStatus.loading: 'loading',
  PillarsDeployStatus.failure: 'failure',
  PillarsDeployStatus.success: 'success',
};
