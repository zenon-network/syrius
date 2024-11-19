// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tokens_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokensState _$TokensStateFromJson(Map<String, dynamic> json) => TokensState(
      status: $enumDecode(_$TokensStatusEnumMap, json['status']),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Token.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TokensStateToJson(TokensState instance) =>
    <String, dynamic>{
      'error': instance.error,
      'status': _$TokensStatusEnumMap[instance.status]!,
      'data': instance.data,
    };

const _$TokensStatusEnumMap = {
  TokensStatus.failure: 'failure',
  TokensStatus.initial: 'initial',
  TokensStatus.success: 'success',
};
