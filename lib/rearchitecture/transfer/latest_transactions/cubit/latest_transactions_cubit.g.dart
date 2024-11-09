// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'latest_transactions_cubit.dart';

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
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$LatestTransactionsStateToJson(
        LatestTransactionsState instance) =>
    <String, dynamic>{
      'status': _$LatestTransactionsStatusEnumMap[instance.status]!,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'error': instance.error,
    };

const _$LatestTransactionsStatusEnumMap = {
  LatestTransactionsStatus.initial: 'initial',
  LatestTransactionsStatus.loading: 'loading',
  LatestTransactionsStatus.failure: 'failure',
  LatestTransactionsStatus.success: 'success',
};
