// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'undelegate_pillar_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UndelegatePillarState _$UndelegatePillarStateFromJson(
        Map<String, dynamic> json) =>
    UndelegatePillarState(
      status: $enumDecodeNullable(
              _$UndelegatePillarStatusEnumMap, json['status']) ??
          UndelegatePillarStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$UndelegatePillarStateToJson(
        UndelegatePillarState instance) =>
    <String, dynamic>{
      'status': _$UndelegatePillarStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$UndelegatePillarStatusEnumMap = {
  UndelegatePillarStatus.initial: 'initial',
  UndelegatePillarStatus.loading: 'loading',
  UndelegatePillarStatus.failure: 'failure',
  UndelegatePillarStatus.success: 'success',
};
