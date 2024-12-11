// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'no_balance_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoBalanceException _$NoBalanceExceptionFromJson(Map<String, dynamic> json) =>
    NoBalanceException(
      message:
          json['message'] as String? ?? 'Empty balance on the selected address',
    );

Map<String, dynamic> _$NoBalanceExceptionToJson(NoBalanceException instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
