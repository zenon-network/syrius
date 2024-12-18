// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillars_qsr_info_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarsQsrInfoState _$PillarsQsrInfoStateFromJson(Map<String, dynamic> json) =>
    PillarsQsrInfoState(
      status:
          $enumDecodeNullable(_$PillarsQsrInfoStatusEnumMap, json['status']) ??
              PillarsQsrInfoStatus.initial,
      data: json['data'] == null
          ? null
          : PillarsQsrInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$PillarsQsrInfoStateToJson(
        PillarsQsrInfoState instance) =>
    <String, dynamic>{
      'status': _$PillarsQsrInfoStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$PillarsQsrInfoStatusEnumMap = {
  PillarsQsrInfoStatus.initial: 'initial',
  PillarsQsrInfoStatus.loading: 'loading',
  PillarsQsrInfoStatus.failure: 'failure',
  PillarsQsrInfoStatus.success: 'success',
};
