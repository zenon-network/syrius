// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latest_transactions_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LatestTransactionsState _$LatestTransactionsStateFromJson(
        Map<String, dynamic> json) =>
    LatestTransactionsState(
      status: $enumDecodeNullable(
              _$LatestTransactionsStatusEnumMap, json['status']) ??
          LatestTransactionsStatus.initial,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => AccountBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AccountBlock>[],
      error: json['error'],
      hasReachedMax: json['hasReachedMax'] as bool? ?? false,
    );

Map<String, dynamic> _$LatestTransactionsStateToJson(
        LatestTransactionsState instance) =>
    <String, dynamic>{
      'status': _$LatestTransactionsStatusEnumMap[instance.status]!,
      'data': instance.data.map((e) => e.toJson()).toList(),
      'error': instance.error,
      'hasReachedMax': instance.hasReachedMax,
    };

const _$LatestTransactionsStatusEnumMap = {
  LatestTransactionsStatus.initial: 'initial',
  LatestTransactionsStatus.failure: 'failure',
  LatestTransactionsStatus.success: 'success',
};
