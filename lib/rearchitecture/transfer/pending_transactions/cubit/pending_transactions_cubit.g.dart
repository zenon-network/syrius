// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transactions_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingTransactionsState _$PendingTransactionsStateFromJson(
        Map<String, dynamic> json) =>
    PendingTransactionsState(
      status: $enumDecode(_$PendingTransactionsStatusEnumMap, json['status']),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AccountBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$PendingTransactionsStateToJson(
        PendingTransactionsState instance) =>
    <String, dynamic>{
      'status': _$PendingTransactionsStatusEnumMap[instance.status]!,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'error': instance.error,
    };

const _$PendingTransactionsStatusEnumMap = {
  PendingTransactionsStatus.initial: 'initial',
  PendingTransactionsStatus.loading: 'loading',
  PendingTransactionsStatus.failure: 'failure',
  PendingTransactionsStatus.success: 'success',
};
