// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_balance_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferBalanceState _$TransferBalanceStateFromJson(
        Map<String, dynamic> json) =>
    TransferBalanceState(
      status:
          $enumDecodeNullable(_$TransferBalanceStatusEnumMap, json['status']) ??
              TransferBalanceStatus.initial,
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, AccountInfo.fromJson(e as Map<String, dynamic>)),
      ),
      error: json['error'],
    );

Map<String, dynamic> _$TransferBalanceStateToJson(
        TransferBalanceState instance) =>
    <String, dynamic>{
      'status': _$TransferBalanceStatusEnumMap[instance.status]!,
      'data': instance.data?.map((k, e) => MapEntry(k, e.toJson())),
      'error': instance.error,
    };

const _$TransferBalanceStatusEnumMap = {
  TransferBalanceStatus.initial: 'initial',
  TransferBalanceStatus.loading: 'loading',
  TransferBalanceStatus.success: 'success',
  TransferBalanceStatus.failure: 'failure',
};
