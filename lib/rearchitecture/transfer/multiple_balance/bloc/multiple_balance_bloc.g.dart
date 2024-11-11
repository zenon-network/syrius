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
      error: json['error'],
    );

Map<String, dynamic> _$MultipleBalanceStateToJson(
        MultipleBalanceState instance) =>
    <String, dynamic>{
      'status': _$MultipleBalanceStatusEnumMap[instance.status]!,
      'data': instance.data?.map((k, e) => MapEntry(k, e.toJson())),
      'error': instance.error,
    };

const _$MultipleBalanceStatusEnumMap = {
  MultipleBalanceStatus.initial: 'initial',
  MultipleBalanceStatus.loading: 'loading',
  MultipleBalanceStatus.success: 'success',
  MultipleBalanceStatus.failure: 'failure',
};
