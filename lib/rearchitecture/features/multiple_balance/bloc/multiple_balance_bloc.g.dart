// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_balance_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultipleBalanceState _$MultipleBalanceStateFromJson(
        Map<String, dynamic> json) =>
    MultipleBalanceState(
      status:
          $enumDecodeNullable(_$MultipleBalanceStatusEnumMap, json['status']) ??
              MultipleBalanceStatus.initial,
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, AccountInfo.fromJson(e as Map<String, dynamic>)),
      ),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MultipleBalanceStateToJson(
        MultipleBalanceState instance) =>
    <String, dynamic>{
      'status': _$MultipleBalanceStatusEnumMap[instance.status]!,
      'data': instance.data?.map((k, e) => MapEntry(k, e.toJson())),
      'error': instance.error?.toJson(),
    };

const _$MultipleBalanceStatusEnumMap = {
  MultipleBalanceStatus.failure: 'failure',
  MultipleBalanceStatus.initial: 'initial',
  MultipleBalanceStatus.loading: 'loading',
  MultipleBalanceStatus.success: 'success',
};
