// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillars_withdraw_qsr_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarsWithdrawQsrState _$PillarsWithdrawQsrStateFromJson(
        Map<String, dynamic> json) =>
    PillarsWithdrawQsrState(
      status: $enumDecodeNullable(
              _$PillarsWithdrawQsrStatusEnumMap, json['status']) ??
          PillarsWithdrawQsrStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$PillarsWithdrawQsrStateToJson(
        PillarsWithdrawQsrState instance) =>
    <String, dynamic>{
      'status': _$PillarsWithdrawQsrStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$PillarsWithdrawQsrStatusEnumMap = {
  PillarsWithdrawQsrStatus.initial: 'initial',
  PillarsWithdrawQsrStatus.loading: 'loading',
  PillarsWithdrawQsrStatus.failure: 'failure',
  PillarsWithdrawQsrStatus.success: 'success',
};
