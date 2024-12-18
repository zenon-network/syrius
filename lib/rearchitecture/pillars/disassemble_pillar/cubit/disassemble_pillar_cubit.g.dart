// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disassemble_pillar_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisassemblePillarState _$DisassemblePillarStateFromJson(
        Map<String, dynamic> json) =>
    DisassemblePillarState(
      status: $enumDecodeNullable(
              _$DisassemblePillarStatusEnumMap, json['status']) ??
          DisassemblePillarStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$DisassemblePillarStateToJson(
        DisassemblePillarState instance) =>
    <String, dynamic>{
      'status': _$DisassemblePillarStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$DisassemblePillarStatusEnumMap = {
  DisassemblePillarStatus.initial: 'initial',
  DisassemblePillarStatus.loading: 'loading',
  DisassemblePillarStatus.failure: 'failure',
  DisassemblePillarStatus.success: 'success',
};
