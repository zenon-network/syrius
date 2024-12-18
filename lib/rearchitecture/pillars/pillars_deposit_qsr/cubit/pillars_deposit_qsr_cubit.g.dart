// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pillars_deposit_qsr_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PillarsDepositQsrState _$PillarsDepositQsrStateFromJson(
        Map<String, dynamic> json) =>
    PillarsDepositQsrState(
      status: $enumDecodeNullable(
              _$PillarsDepositQsrStatusEnumMap, json['status']) ??
          PillarsDepositQsrStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$PillarsDepositQsrStateToJson(
        PillarsDepositQsrState instance) =>
    <String, dynamic>{
      'status': _$PillarsDepositQsrStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$PillarsDepositQsrStatusEnumMap = {
  PillarsDepositQsrStatus.initial: 'initial',
  PillarsDepositQsrStatus.loading: 'loading',
  PillarsDepositQsrStatus.failure: 'failure',
  PillarsDepositQsrStatus.success: 'success',
};
