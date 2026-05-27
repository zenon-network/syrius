// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegate_pillar_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegatePillarState _$DelegatePillarStateFromJson(Map<String, dynamic> json) =>
    DelegatePillarState(
      status:
          $enumDecodeNullable(_$DelegatePillarStatusEnumMap, json['status']) ??
          DelegatePillarStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$DelegatePillarStateToJson(
  DelegatePillarState instance,
) => <String, dynamic>{
  'status': _$DelegatePillarStatusEnumMap[instance.status]!,
  'data': instance.data?.toJson(),
  'error': instance.error,
};

const _$DelegatePillarStatusEnumMap = {
  DelegatePillarStatus.initial: 'initial',
  DelegatePillarStatus.loading: 'loading',
  DelegatePillarStatus.failure: 'failure',
  DelegatePillarStatus.success: 'success',
};
