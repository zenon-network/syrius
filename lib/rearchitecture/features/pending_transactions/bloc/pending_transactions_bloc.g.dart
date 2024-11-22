// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transactions_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingTransactionsState _$PendingTransactionsStateFromJson(
        Map<String, dynamic> json) =>
    PendingTransactionsState(
      status: $enumDecodeNullable(
              _$PendingTransactionsStatusEnumMap, json['status']) ??
          PendingTransactionsStatus.initial,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => AccountBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AccountBlock>[],
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
      hasReachedMax: json['hasReachedMax'] as bool? ?? false,
    );

Map<String, dynamic> _$PendingTransactionsStateToJson(
        PendingTransactionsState instance) =>
    <String, dynamic>{
      'status': _$PendingTransactionsStatusEnumMap[instance.status]!,
      'data': instance.data.map((e) => e.toJson()).toList(),
      'error': instance.error?.toJson(),
      'hasReachedMax': instance.hasReachedMax,
    };

const _$PendingTransactionsStatusEnumMap = {
  PendingTransactionsStatus.initial: 'initial',
  PendingTransactionsStatus.failure: 'failure',
  PendingTransactionsStatus.success: 'success',
};
