// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_pillar_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePillarState _$UpdatePillarStateFromJson(Map<String, dynamic> json) =>
    UpdatePillarState(
      status:
          $enumDecodeNullable(_$UpdatePillarStatusEnumMap, json['status']) ??
              UpdatePillarStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$UpdatePillarStateToJson(UpdatePillarState instance) =>
    <String, dynamic>{
      'status': _$UpdatePillarStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$UpdatePillarStatusEnumMap = {
  UpdatePillarStatus.initial: 'initial',
  UpdatePillarStatus.loading: 'loading',
  UpdatePillarStatus.failure: 'failure',
  UpdatePillarStatus.success: 'success',
};
